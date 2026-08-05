package app.shootingcompanion.shot_timer

internal data class NativeTimerConfiguration(
    val delayMode: String,
    val fixedDelayMicros: Long,
    val randomDelayMinimumMicros: Long,
    val randomDelayMaximumMicros: Long,
    val maximumShots: Int?,
    val inactivityTimeoutMicros: Long?,
    val sampleRate: Int?,
    val sensitivity: Double,
    val echoLockoutMicros: Long,
    val beepBlankingMicros: Long,
) {
    init {
        require(delayMode in setOf("immediate", "fixed", "random"))
        require(fixedDelayMicros >= 0)
        require(randomDelayMinimumMicros >= 0)
        require(randomDelayMaximumMicros >= randomDelayMinimumMicros)
        require(maximumShots == null || maximumShots > 0)
        require(inactivityTimeoutMicros == null || inactivityTimeoutMicros > 0)
        require(sampleRate == null || sampleRate in 8_000..192_000)
        require(sensitivity in 0.0..1.0)
        require(echoLockoutMicros >= 0)
        require(beepBlankingMicros >= 0)
    }

    fun actualDelayMicros(randomLong: (Long, Long) -> Long): Long =
        when (delayMode) {
            "immediate" -> 0
            "fixed" -> fixedDelayMicros
            else -> {
                if (randomDelayMinimumMicros == randomDelayMaximumMicros) {
                    randomDelayMinimumMicros
                } else {
                    randomLong(randomDelayMinimumMicros, randomDelayMaximumMicros + 1)
                }
            }
        }

    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromMap(map: Map<String, Any?>): NativeTimerConfiguration {
            require(map["mode"] == "acousticLiveFire") {
                "The Android audio engine only supports acousticLiveFire."
            }
            val calibration = map["calibration"] as? Map<String, Any?>
            return NativeTimerConfiguration(
                delayMode = map["delayMode"] as? String ?: "immediate",
                fixedDelayMicros = (map["fixedDelayMicros"] as? Number)?.toLong() ?: 0,
                randomDelayMinimumMicros =
                    (map["randomDelayMinimumMicros"] as? Number)?.toLong() ?: 2_000_000,
                randomDelayMaximumMicros =
                    (map["randomDelayMaximumMicros"] as? Number)?.toLong() ?: 4_000_000,
                maximumShots = (map["maximumShots"] as? Number)?.toInt(),
                inactivityTimeoutMicros =
                    (map["inactivityTimeoutMicros"] as? Number)?.toLong(),
                sampleRate = (calibration?.get("sampleRate") as? Number)?.toInt(),
                sensitivity =
                    (calibration?.get("sensitivity") as? Number)?.toDouble() ?: 0.6,
                echoLockoutMicros =
                    (calibration?.get("echoLockoutMicros") as? Number)?.toLong() ?: 80_000,
                beepBlankingMicros =
                    (calibration?.get("beepBlankingMicros") as? Number)?.toLong() ?: 160_000,
            )
        }
    }
}
