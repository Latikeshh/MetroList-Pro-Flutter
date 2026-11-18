<#
.SYNOPSIS
    AI-assisted Kotlin-to-Dart conversion for a complete Kotlin source file.

.DESCRIPTION
    Converts YouTube.kt into YouTubeService.dart using the Gemini API.
    Unlike the original script, this does NOT put Kotlin inside a comment.
    It sends the complete Kotlin source to the model and requests a real Dart
    translation while preserving every declaration, method, branch and behavior.

    Requirements:
      - PowerShell 7+ (recommended)
      - A Gemini API key
      - Internet access

    Set the API key before running:
      $env:GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"

    Run:
      .\convert_youtube_kt_to_dart.ps1 `
        -SourceFile ".\YouTube.kt" `
        -TargetFile ".\YouTubeService.dart"

    You can change the model with -Model. The default is gemini-2.5-pro.
#>

[CmdletBinding()]
param(
    [string]$SourceFile = "C:\Users\Latikesh\AndroidStudioProjects\Metrolist\innertube\src\main\kotlin\com\metrolist\innertube\YouTube.kt",
    [string]$TargetFile = "C:\Users\Latikesh\AndroidStudioProjects\Metrolist\lib\services\innertube\youtube_service.dart",
    [string]$Model = "gemini-2.5-pro",
    [int]$MaxOutputTokens = 65536,
    [switch]$KeepRawResponse
)

$ErrorActionPreference = "Stop"

# -------------------- Validate input --------------------

if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
    throw "Source file not found: $SourceFile"
}

$apiKey = $env:GEMINI_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "GEMINI_API_KEY environment variable is missing. Set it before running this script."
}

$sourcePath = (Resolve-Path -LiteralPath $SourceFile).Path
$targetFullPath = [System.IO.Path]::GetFullPath($TargetFile)
$sourceCode = [System.IO.File]::ReadAllText($sourcePath)

if ([string]::IsNullOrWhiteSpace($sourceCode)) {
    throw "Source file is empty."
}

$sourceLines = ($sourceCode -split "`r?`n").Count
Write-Host "Source: $sourcePath" -ForegroundColor Cyan
Write-Host "Lines : $sourceLines" -ForegroundColor Cyan
Write-Host "Model : $Model" -ForegroundColor Cyan
Write-Host "Target: $targetFullPath" -ForegroundColor Cyan

# -------------------- Conversion instructions --------------------

$prompt = @'
You are a senior Kotlin and Dart engineer performing a behavior-preserving
source-to-source migration.

TASK:
Translate the complete Kotlin source file supplied below into real, idiomatic
Dart source code for a file named YouTubeService.dart.

NON-NEGOTIABLE RULES:
1. Translate EVERY declaration and EVERY method. Do not omit, summarize,
   simplify, stub, or replace any method with TODO, UnimplementedError,
   placeholder data, or generic raw-JSON behavior.
2. Preserve the original behavior, branching, ordering, default values,
   nullability, error handling, pagination, retries, concurrency limits,
   transformations, and edge cases.
3. Convert Kotlin constructs correctly:
   - suspend functions / coroutines to Dart Future and async/await
   - Result<T> and runCatching to an explicit Dart result/error strategy
   - nullable types and safe calls to Dart null safety
   - data classes / sealed classes / enums to corresponding Dart types
   - collection operators to equivalent Dart transformations
   - InputStream wrappers to appropriate Dart stream abstractions
   - Proxy, cookies, authentication, locale and request state to equivalent
     Dart APIs where possible
4. Do not invent missing model definitions or pretend external Kotlin classes
   already exist in Dart. Keep references to missing dependencies explicit and
   list them in a dependency report after the code.
5. Preserve public method names and their meaning. Use Dart naming conventions
   where appropriate, but do not lose any public operation.
6. Do not place the Kotlin source in comments. The output must be Dart code.
7. Do not return explanations before or inside the code.
8. If a Kotlin dependency cannot be represented because its definition is not
   present in this source file, retain a clearly named Dart dependency reference
   and report the exact missing Kotlin type/package. Do not silently delete the
   feature.
9. Do not claim the result is compile-ready if external model, page, response,
   InnerTube, constants, or utility classes are absent.
10. Check that every top-level function/property/class in the Kotlin input has
    a corresponding Dart implementation or explicit dependency mapping.
11. Output the complete file. If you cannot fit the complete translation in
    one response, output a clear truncation marker rather than silently ending.

DART TARGET:
- Use null-safe Dart.
- Prefer package:http for HTTP only if that preserves the original transport
  behavior; otherwise define a transport abstraction and report what must be
  implemented.
- Avoid Flutter UI dependencies; this is a service file.
- Keep the service organized and preserve the original logical sections.
- Add concise comments only where they clarify non-obvious Kotlin behavior.

OUTPUT FORMAT:
Return exactly:
<<<DART_SOURCE>>>
[complete Dart source code]
<<<DEPENDENCY_REPORT>>>
[all external Kotlin dependencies that require separate Dart equivalents]
<<<CONVERSION_CHECKLIST>>>
[method/declaration coverage and any known semantic gaps]

KOTLIN SOURCE BEGINS:
'@

$fullPrompt = $prompt + "`n" + $sourceCode + "`nKOTLIN SOURCE ENDS."

$uri = "https://generativelanguage.googleapis.com/v1beta/models/$($Model):generateContent?key=$([uri]::EscapeDataString($apiKey))"

$body = @{
    contents = @(
        @{
            role = "user"
            parts = @(
                @{ text = $fullPrompt }
            )
        }
    )
    generationConfig = @{
        temperature = 0.1
        maxOutputTokens = $MaxOutputTokens
        responseMimeType = "text/plain"
    }
} | ConvertTo-Json -Depth 10

Write-Host "`nSending complete source to Gemini for conversion..." -ForegroundColor Yellow
Write-Host "This may take several minutes for a large file." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod `
        -Method Post `
        -Uri $uri `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
        -TimeoutSec 1800
}
catch {
    $details = $_.ErrorDetails.Message
    if ([string]::IsNullOrWhiteSpace($details)) { $details = $_.Exception.Message }
    throw "Gemini API request failed: $details"
}

# -------------------- Extract generated response --------------------

$candidate = $response.candidates | Select-Object -First 1
if (-not $candidate) {
    throw "Gemini returned no candidate. Check API quota, model access, and source size."
}

$finishReason = [string]$candidate.finishReason
$generatedText = ($candidate.content.parts | ForEach-Object { $_.text }) -join "`n"

if ([string]::IsNullOrWhiteSpace($generatedText)) {
    throw "Gemini returned an empty conversion."
}

if ($KeepRawResponse) {
    $rawPath = "$targetFullPath.gemini-response.txt"
    [System.IO.File]::WriteAllText(
            $rawPath,
            $generatedText,
            [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host "Raw model response saved: $rawPath" -ForegroundColor DarkGray
}

# -------------------- Extract Dart source --------------------

$startMarker = "<<<DART_SOURCE>>>"
$endMarker = "<<<DEPENDENCY_REPORT>>>"

$startIndex = $generatedText.IndexOf($startMarker, [System.StringComparison]::Ordinal)
$endIndex = $generatedText.IndexOf($endMarker, [System.StringComparison]::Ordinal)

if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex) {
    throw "The model did not return the required complete-source markers. No output file was written. Use -KeepRawResponse to inspect the response."
}

$dartCode = $generatedText.Substring(
        $startIndex + $startMarker.Length,
        $endIndex - ($startIndex + $startMarker.Length)
).Trim()

# Remove optional Markdown fences if the model added them.
$dartCode = $dartCode -replace '^\s*```(?:dart)?\s*', ''
$dartCode = $dartCode -replace '\s*```\s*$', ''

if ([string]::IsNullOrWhiteSpace($dartCode)) {
    throw "Extracted Dart source is empty. No output file was written."
}

if ($finishReason -eq "MAX_TOKENS") {
    throw "Gemini hit the output-token limit. The response is incomplete, so the script deliberately did not save it as a completed Dart file. Increase -MaxOutputTokens if the selected model allows it, or use a larger-output model."
}

# -------------------- Save Dart file and report --------------------

$targetDirectory = Split-Path -Parent $targetFullPath
if (-not [string]::IsNullOrWhiteSpace($targetDirectory) -and -not (Test-Path $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
}

[System.IO.File]::WriteAllText(
        $targetFullPath,
        $dartCode + "`n",
        [System.Text.UTF8Encoding]::new($false)
)

$reportStart = $generatedText.IndexOf("<<<DEPENDENCY_REPORT>>>", [System.StringComparison]::Ordinal)
$checkStart = $generatedText.IndexOf("<<<CONVERSION_CHECKLIST>>>", [System.StringComparison]::Ordinal)

if ($reportStart -ge 0 -and $checkStart -gt $reportStart) {
    $reportText = $generatedText.Substring($reportStart, $checkStart - $reportStart).Trim()
    $checkText = $generatedText.Substring($checkStart).Trim()
    $reportPath = "$targetFullPath.conversion-report.txt"
    [System.IO.File]::WriteAllText(
            $reportPath,
            $reportText + "`r`n`r`n" + $checkText + "`r`n",
            [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host "Dependency/checklist report: $reportPath" -ForegroundColor Cyan
}

Write-Host "`nConversion output written: $targetFullPath" -ForegroundColor Green
Write-Host "Dart lines: $(($dartCode -split "`r?`n").Count)" -ForegroundColor Green
Write-Host "API finish reason: $finishReason" -ForegroundColor DarkGray
Write-Host "`nIMPORTANT: Run 'dart format $targetFullPath' and 'flutter analyze'." -ForegroundColor Yellow
Write-Host "The report identifies Kotlin dependencies that must also be ported." -ForegroundColor Yellow
