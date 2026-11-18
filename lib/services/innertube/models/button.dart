class Button {
  final String? endpoint;

  Button({this.endpoint});

  factory Button.fromJson(Map<String, dynamic> json) {
    return Button(
      endpoint: json['buttonRenderer']?['navigationEndpoint']?['watchEndpoint']?['videoId'] as String?,
    );
  }
}
