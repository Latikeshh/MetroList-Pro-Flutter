class FeedbackResponse {
  final List<FeedbackStatus>? feedbackResponses;

  FeedbackResponse({this.feedbackResponses});

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      feedbackResponses: (json['feedbackResponses'] as List?)
          ?.map((e) => FeedbackStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeedbackStatus {
  final bool isProcessed;

  FeedbackStatus({required this.isProcessed});

  factory FeedbackStatus.fromJson(Map<String, dynamic> json) {
    return FeedbackStatus(
      isProcessed: json['isProcessed'] as bool? ?? false,
    );
  }
}
