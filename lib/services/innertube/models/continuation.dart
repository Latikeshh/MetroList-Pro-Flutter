class Continuation {
  final String continuation;

  Continuation({required this.continuation});

  factory Continuation.fromJson(Map<String, dynamic> json) {
    final token = json['nextContinuationData']?['continuation'] as String?
        ?? json['nextRadioContinuationData']?['continuation'] as String?
        ?? json['invalidationContinuationData']?['continuation'] as String?
        ?? '';
    return Continuation(continuation: token);
  }
}
