class CreatePlaylistResponse {
  final String playlistId;

  CreatePlaylistResponse({required this.playlistId});

  factory CreatePlaylistResponse.fromJson(Map<String, dynamic> json) {
    return CreatePlaylistResponse(
      playlistId: json['playlistId'] as String? ?? '',
    );
  }
}
