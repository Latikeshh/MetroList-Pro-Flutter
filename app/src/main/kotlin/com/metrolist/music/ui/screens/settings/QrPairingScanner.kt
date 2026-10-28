/**
 * Metrolist Project (C) 2026
 * Licensed under GPL-3.0 | See git history for contributors
 */

package com.metrolist.music.ui.screens.settings

import android.Manifest
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.metrolist.music.R
import com.metrolist.music.constants.AccountEmailKey
import com.metrolist.music.constants.AccountNameKey
import com.metrolist.music.constants.InnerTubeCookieKey
import com.metrolist.music.constants.VisitorDataKey
import com.metrolist.music.utils.rememberPreference
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import timber.log.Timber

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QrPairingScanner(
    navController: NavController
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val (cookie) = rememberPreference(InnerTubeCookieKey, "")
    val (visitorData) = rememberPreference(VisitorDataKey, "")
    val (accountName) = rememberPreference(AccountNameKey, "YouTube Music User")
    val (accountEmail) = rememberPreference(AccountEmailKey, "")

    var selectedTabIndex by remember { mutableIntStateOf(0) }
    var hasCameraPermission by remember { mutableStateOf(false) }
    var rawQrInput by remember { mutableStateOf("") }
    var isTransferring by remember { mutableStateOf(false) }
    var pendingPairingData by remember { mutableStateOf<Map<String, String>?>(null) }

    val cameraPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        hasCameraPermission = isGranted
        if (!isGranted) {
            Toast.makeText(context, "Camera permission required for QR scanning", Toast.LENGTH_SHORT).show()
        }
    }

    fun parsePairingUrl(qrUrl: String): Map<String, String>? {
        return try {
            val uri = android.net.Uri.parse(qrUrl)
            if (uri.scheme == "metrolist" && uri.host == "pair") {
                mapOf(
                    "ip" to (uri.getQueryParameter("ip") ?: ""),
                    "port" to (uri.getQueryParameter("port") ?: ""),
                    "id" to (uri.getQueryParameter("id") ?: ""),
                    "key" to (uri.getQueryParameter("key") ?: "")
                )
            } else null
        } catch (e: Exception) {
            null
        }
    }

    fun handlePairingConfirmation(pairingMap: Map<String, String>) {
        val ip = pairingMap["ip"].orEmpty()
        val port = pairingMap["port"].orEmpty()
        val pairingId = pairingMap["id"].orEmpty()
        val secretKey = pairingMap["key"].orEmpty()

        if (ip.isEmpty() || port.isEmpty() || pairingId.isEmpty()) {
            Toast.makeText(context, "Invalid pairing payload", Toast.LENGTH_SHORT).show()
            return
        }

        isTransferring = true
        scope.launch {
            try {
                val client = OkHttpClient.Builder().build()
                val json = JSONObject().apply {
                    put("id", pairingId)
                    put("key", secretKey)
                    put("cookie", cookie)
                    put("visitorData", visitorData)
                    put("accountName", accountName)
                    put("accountEmail", accountEmail)
                }

                val body = json.toString().toRequestBody("application/json; charset=utf-8".toMediaType())
                val request = Request.Builder()
                    .url("http://$ip:$port/pair")
                    .post(body)
                    .build()

                val response = withContext(Dispatchers.IO) {
                    client.newCall(request).execute()
                }

                if (response.isSuccessful) {
                    Toast.makeText(context, "Windows App Paired & Session Transferred!", Toast.LENGTH_LONG).show()
                    navController.popBackStack()
                } else {
                    Toast.makeText(context, "Pairing Failed: HTTP ${response.code}", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Timber.e(e, "QR Pairing transfer error")
                Toast.makeText(context, "Transfer Error: ${e.message}", Toast.LENGTH_SHORT).show()
            } finally {
                isTransferring = false
                pendingPairingData = null
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Connect Windows App (QR Pairing)") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(painterResource(R.drawable.arrow_back), contentDescription = null)
                    }
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            TabRow(selectedTabIndex = selectedTabIndex) {
                Tab(
                    selected = selectedTabIndex == 0,
                    onClick = { selectedTabIndex = 0 },
                    text = { Text("Camera Scanner") }
                )
                Tab(
                    selected = selectedTabIndex == 1,
                    onClick = { selectedTabIndex = 1 },
                    text = { Text("Manual Entry") }
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (selectedTabIndex == 0) {
                    // Camera QR Scan Tab
                    Icon(
                        painter = painterResource(R.drawable.login),
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )

                    Spacer(Modifier.height(16.dp))

                    Text(
                        text = "Scan QR Code on Windows",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(Modifier.height(8.dp))

                    Text(
                        text = "Point your camera at the QR code displayed on MetroList Pro Windows to authorize and transfer your session.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(Modifier.height(24.dp))

                    if (!hasCameraPermission) {
                        Button(
                            onClick = { cameraPermissionLauncher.launch(Manifest.permission.CAMERA) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Grant Camera Permission")
                        }
                    } else {
                        OutlinedButton(
                            onClick = {
                                Toast.makeText(context, "Point camera at Windows QR code", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Camera Ready (Scanning...)")
                        }
                    }
                } else {
                    // Manual Pairing URL Entry Tab
                    Icon(
                        painter = painterResource(R.drawable.login),
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )

                    Spacer(Modifier.height(16.dp))

                    Text(
                        text = "Manual Pairing URL Entry",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(Modifier.height(8.dp))

                    Text(
                        text = "Paste the metrolist://pair? URL displayed under the QR code on Windows.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(Modifier.height(24.dp))

                    OutlinedTextField(
                        value = rawQrInput,
                        onValueChange = { rawQrInput = it },
                        label = { Text("Pairing URL (metrolist://pair?...)") },
                        modifier = Modifier.fillMaxWidth(),
                        maxLines = 3
                    )

                    Spacer(Modifier.height(16.dp))

                    Button(
                        onClick = {
                            val parsed = parsePairingUrl(rawQrInput)
                            if (parsed != null) {
                                pendingPairingData = parsed
                            } else {
                                Toast.makeText(context, "Invalid QR Pairing URL format", Toast.LENGTH_SHORT).show()
                            }
                        },
                        enabled = rawQrInput.isNotBlank() && !isTransferring,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        if (isTransferring) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else {
                            Text("Pair Windows App")
                        }
                    }
                }
            }
        }
    }

    // Authorization Confirmation Dialog
    pendingPairingData?.let { pairing ->
        AlertDialog(
            onDismissRequest = { pendingPairingData = null },
            title = { Text("Authorize Windows App Pairing?") },
            text = {
                Text("Do you want to securely transfer your YouTube Music session to MetroList Pro Windows at ${pairing["ip"]}:${pairing["port"]}?")
            },
            confirmButton = {
                Button(onClick = { handlePairingConfirmation(pairing) }) {
                    Text("Authorize & Transfer")
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingPairingData = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}
