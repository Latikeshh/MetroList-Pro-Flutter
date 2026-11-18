class ContinuationResponse {
  final List<dynamic>? onResponseReceivedActions;

  ContinuationResponse({this.onResponseReceivedActions});

  factory ContinuationResponse.fromJson(Map<String, dynamic> json) {
    return ContinuationResponse(
      onResponseReceivedActions: json['onResponseReceivedActions'] as List?,
    );
  }
}
