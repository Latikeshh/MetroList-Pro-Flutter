class Endpoint {
  final String? browseId;
  final String? videoId;
  final String? playlistId;
  final String? params;

  Endpoint({
    this.browseId,
    this.videoId,
    this.playlistId,
    this.params,
  });

  factory Endpoint.fromJson(Map<String, dynamic> json) {
    final browse = json['browseEndpoint'];
    final watch = json['watchEndpoint'];
    final playlist = json['watchPlaylistEndpoint'];

    return Endpoint(
      browseId: browse?['browseId'] as String?,
      params: browse?['params'] as String? ?? watch?['params'] as String?,
      videoId: watch?['videoId'] as String?,
      playlistId: watch?['playlistId'] as String? ?? playlist?['playlistId'] as String?,
    );
  }
}
