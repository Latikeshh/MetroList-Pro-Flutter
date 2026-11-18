class PlayerResponse {
  final Map<String, dynamic>? playabilityStatus;
  final Map<String, dynamic>? playerConfig;
  final Map<String, dynamic>? streamingData;
  final Map<String, dynamic>? videoDetails;
  final Map<String, dynamic>? playbackTracking;

  PlayerResponse({
    this.playabilityStatus,
    this.playerConfig,
    this.streamingData,
    this.videoDetails,
    this.playbackTracking,
  });

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    return PlayerResponse(
      playabilityStatus: json['playabilityStatus'] as Map<String, dynamic>?,
      playerConfig: json['playerConfig'] as Map<String, dynamic>?,
      streamingData: json['streamingData'] as Map<String, dynamic>?,
      videoDetails: json['videoDetails'] as Map<String, dynamic>?,
      playbackTracking: json['playbackTracking'] as Map<String, dynamic>?,
    );
  }
}
