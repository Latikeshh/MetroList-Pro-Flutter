class TranscriptCue {
  final String text;
  final int startOffsetMs;
  final int durationMs;

  TranscriptCue({
    required this.text,
    required this.startOffsetMs,
    required this.durationMs,
  });
}

class GetTranscriptResponse {
  final List<TranscriptCue> cues;

  GetTranscriptResponse({required this.cues});

  factory GetTranscriptResponse.fromJson(Map<String, dynamic> json) {
    final List<TranscriptCue> result = [];
    try {
      final actions = json['actions'] as List?;
      if (actions != null && actions.isNotEmpty) {
        final content = actions.first['updateEngagementPanelAction']?['content'];
        final bodyRenderer = content?['transcriptRenderer']?['body']?['transcriptBodyRenderer'];
        final cueGroups = bodyRenderer?['cueGroups'] as List?;
        if (cueGroups != null) {
          for (final group in cueGroups) {
            final cueList = group['transcriptCueGroupRenderer']?['cues'] as List?;
            if (cueList != null) {
              for (final c in cueList) {
                final renderer = c['transcriptCueRenderer'];
                if (renderer != null) {
                  final text = renderer['cue']?['simpleText'] as String? ?? '';
                  final start = int.tryParse(renderer['startOffsetMs']?.toString() ?? '0') ?? 0;
                  final duration = int.tryParse(renderer['durationMs']?.toString() ?? '0') ?? 0;
                  result.add(TranscriptCue(
                    text: text,
                    startOffsetMs: start,
                    durationMs: duration,
                  ));
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return GetTranscriptResponse(cues: result);
  }
}
