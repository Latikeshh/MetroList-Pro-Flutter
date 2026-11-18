library;

class BrowseResponse {
  final Map<String, dynamic>? contents;
  final Map<String, dynamic>? continuationContents;
  final Map<String, dynamic>? header;

  const BrowseResponse({
    this.contents,
    this.continuationContents,
    this.header,
  });

  factory BrowseResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return BrowseResponse(
        contents: json['contents'] is Map<String, dynamic> ? json['contents'] : null,
        continuationContents: json['continuationContents'] is Map<String, dynamic>
            ? json['continuationContents']
            : null,
        header: json['header'] is Map<String, dynamic> ? json['header'] : null,
      );
    }
    return const BrowseResponse();
  }
}

class SearchResponse {
  final Map<String, dynamic>? contents;

  const SearchResponse({this.contents});

  factory SearchResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return SearchResponse(
        contents: json['contents'] is Map<String, dynamic> ? json['contents'] : null,
      );
    }
    return const SearchResponse();
  }
}

class NextResponse {
  final Map<String, dynamic>? contents;
  final Map<String, dynamic>? continuationContents;

  const NextResponse({
    this.contents,
    this.continuationContents,
  });

  factory NextResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return NextResponse(
        contents: json['contents'] is Map<String, dynamic> ? json['contents'] : null,
        continuationContents: json['continuationContents'] is Map<String, dynamic>
            ? json['continuationContents']
            : null,
      );
    }
    return const NextResponse();
  }
}

class PlayerResponse {
  final Map<String, dynamic>? playabilityStatus;
  final Map<String, dynamic>? videoDetails;
  final Map<String, dynamic>? streamingData;

  const PlayerResponse({
    this.playabilityStatus,
    this.videoDetails,
    this.streamingData,
  });

  factory PlayerResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return PlayerResponse(
        playabilityStatus: json['playabilityStatus'] is Map<String, dynamic>
            ? json['playabilityStatus']
            : null,
        videoDetails: json['videoDetails'] is Map<String, dynamic>
            ? json['videoDetails']
            : null,
        streamingData: json['streamingData'] is Map<String, dynamic>
            ? json['streamingData']
            : null,
      );
    }
    return const PlayerResponse();
  }
}

class ContinuationResponse {
  final Map<String, dynamic>? continuationContents;

  const ContinuationResponse({this.continuationContents});

  factory ContinuationResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ContinuationResponse(
        continuationContents: json['continuationContents'] is Map<String, dynamic>
            ? json['continuationContents']
            : null,
      );
    }
    return const ContinuationResponse();
  }
}

class AccountMenuResponse {
  final List<dynamic>? actions;

  const AccountMenuResponse({this.actions});

  factory AccountMenuResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic> && json['actions'] is List) {
      return AccountMenuResponse(actions: json['actions']);
    }
    return const AccountMenuResponse();
  }
}

class GetQueueResponse {
  final Map<String, dynamic>? queueData;

  const GetQueueResponse({this.queueData});

  factory GetQueueResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return GetQueueResponse(
        queueData: json['queueData'] is Map<String, dynamic> ? json['queueData'] : null,
      );
    }
    return const GetQueueResponse();
  }
}

class GetTranscriptResponse {
  final List<dynamic>? actions;

  const GetTranscriptResponse({this.actions});

  factory GetTranscriptResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic> && json['actions'] is List) {
      return GetTranscriptResponse(actions: json['actions']);
    }
    return const GetTranscriptResponse();
  }
}

class CreatePlaylistResponse {
  final String? playlistId;

  const CreatePlaylistResponse({this.playlistId});

  factory CreatePlaylistResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return CreatePlaylistResponse(
        playlistId: json['playlistId']?.toString(),
      );
    }
    return const CreatePlaylistResponse();
  }
}

class EditPlaylistResponse {
  final String? status;
  final List<dynamic>? actions;

  const EditPlaylistResponse({this.status, this.actions});

  factory EditPlaylistResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return EditPlaylistResponse(
        status: json['status']?.toString(),
        actions: json['actions'] is List ? json['actions'] : null,
      );
    }
    return const EditPlaylistResponse();
  }
}

class FeedbackResponse {
  final bool success;

  const FeedbackResponse({this.success = false});

  factory FeedbackResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return FeedbackResponse(
        success: json['status'] == 'STATUS_SUCCESS' || json['feedbackId'] != null,
      );
    }
    return const FeedbackResponse();
  }
}

class GetSearchSuggestionsResponse {
  final Map<String, dynamic>? contents;

  const GetSearchSuggestionsResponse({this.contents});

  factory GetSearchSuggestionsResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return GetSearchSuggestionsResponse(
        contents: json['contents'] is Map<String, dynamic> ? json['contents'] : null,
      );
    }
    return const GetSearchSuggestionsResponse();
  }
}

