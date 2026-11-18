class GetQueueResponse {
  final List<Map<String, dynamic>>? queueDatas;

  GetQueueResponse({this.queueDatas});

  factory GetQueueResponse.fromJson(Map<String, dynamic> json) {
    return GetQueueResponse(
      queueDatas: (json['queueDatas'] as List?)
          ?.map((e) => e['content'] as Map<String, dynamic>)
          .toList(),
    );
  }
}
