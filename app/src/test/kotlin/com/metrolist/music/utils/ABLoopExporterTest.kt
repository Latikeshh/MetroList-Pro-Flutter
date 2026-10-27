/**
 * Metrolist Pro Project (C) 2026
 * Licensed under GPL-3.0 | See git history for contributors
 */

package com.metrolist.music.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ABLoopExporterTest {

    @Test
    fun `formatPreciseTime formats milliseconds accurately`() {
        assertEquals("00:00.0", formatPreciseTime(0L))
        assertEquals("01:23.4", formatPreciseTime(83400L))
        assertEquals("10:05.9", formatPreciseTime(605900L))
        assertEquals("1:00:00.0", formatPreciseTime(3600000L))
        assertEquals("--:--.-", formatPreciseTime(null))
        assertEquals("--:--.-", formatPreciseTime(-500L))
    }

    private fun isValidLoopRange(startMs: Long?, endMs: Long?): Boolean {
        return startMs != null && endMs != null && startMs < endMs
    }

    @Test
    fun `a-b loop range boundary validation`() {
        assertTrue(isValidLoopRange(15000L, 45000L))
        assertFalse(isValidLoopRange(50000L, 30000L))
        assertFalse(isValidLoopRange(30000L, 30000L))
        assertFalse(isValidLoopRange(null, 45000L))
        assertFalse(isValidLoopRange(15000L, null))
    }
}
