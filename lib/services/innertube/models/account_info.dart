class AccountInfo {
  final String name;
  final String? email;
  final String? channelHandle;
  final String? thumbnailUrl;

  AccountInfo({
    required this.name,
    this.email,
    this.channelHandle,
    this.thumbnailUrl,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      channelHandle: json['channelHandle'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'channelHandle': channelHandle,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
