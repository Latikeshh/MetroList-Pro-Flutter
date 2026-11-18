class YouTubeAccount {
  final String name;
  final String? email;
  final String? channelHandle;
  final String? thumbnailUrl;

  YouTubeAccount({
    required this.name,
    this.email,
    this.channelHandle,
    this.thumbnailUrl,
  });

  factory YouTubeAccount.fromJson(Map<String, dynamic> json) {
    return YouTubeAccount(
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      channelHandle: json['channelHandle'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
