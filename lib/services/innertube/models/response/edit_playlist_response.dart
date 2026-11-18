class EditPlaylistResponse {
  final Map<String, dynamic>? newHeader;

  EditPlaylistResponse({this.newHeader});

  factory EditPlaylistResponse.fromJson(Map<String, dynamic> json) {
    return EditPlaylistResponse(
      newHeader: json['newHeader'] as Map<String, dynamic>?,
    );
  }
}
