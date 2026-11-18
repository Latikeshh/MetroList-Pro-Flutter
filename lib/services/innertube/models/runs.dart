library;

import 'navigation_endpoint.dart';

class Run {
  final String text;
  final NavigationEndpoint? navigationEndpoint;

  const Run({
    required this.text,
    this.navigationEndpoint,
  });

  factory Run.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Run(text: '');
    final text = json['text']?.toString() ?? '';
    final rawEndpoint = json['navigationEndpoint'];
    final endpoint = rawEndpoint is Map<String, dynamic>
        ? NavigationEndpoint.fromJson(rawEndpoint)
        : null;
    return Run(text: text, navigationEndpoint: endpoint);
  }
}

class Runs {
  final List<Run> runs;

  const Runs({required this.runs});

  factory Runs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Runs(runs: []);
    final rawRuns = json['runs'];
    if (rawRuns is List) {
      final parsed = rawRuns
          .whereType<Map<String, dynamic>>()
          .map((r) => Run.fromJson(r))
          .toList();
      return Runs(runs: parsed);
    }
    return const Runs(runs: []);
  }

  static List<List<Run>> splitBySeparator(List<Run> runsList) {
    final List<List<Run>> res = [];
    List<Run> tmp = [];
    for (final run in runsList) {
      if (run.text.trim() == '•') {
        res.add(tmp);
        tmp = [];
      } else {
        tmp.add(run);
      }
    }
    res.add(tmp);
    return res;
  }

  static List<Run> splitArtistsByConjunction(List<Run> runsList, {List<String> conjunctions = const ['and']}) {
    final List<Run> result = [];
    final patternStr = conjunctions.isNotEmpty
        ? ' (${conjunctions.map(RegExp.escape).join('|')}) | & '
        : ' & ';
    final conjunctionPattern = RegExp(patternStr, caseSensitive: false);

    for (final run in runsList) {
      final text = run.text;
      if (text.contains(conjunctionPattern)) {
        final parts = text.split(conjunctionPattern);
        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];
          if (part.trim().isNotEmpty) {
            result.add(Run(
              text: part.trim(),
              navigationEndpoint: i == 0 ? run.navigationEndpoint : null,
            ));
          }
        }
      } else if (text.trim().toLowerCase() == '&' ||
          text.trim() == '•' ||
          conjunctions.any((c) => text.trim().toLowerCase() == c.toLowerCase())) {
        // Skip conjunction separators
      } else {
        result.add(run);
      }
    }
    return result;
  }

  static List<List<Run>> clean(List<List<Run>> groups, {List<String> conjunctions = const ['and']}) {
    if (groups.isEmpty) return groups;
    final firstGroup = groups.first;
    final hasArtistSignals = firstGroup.any((r) => r.navigationEndpoint != null) ||
        firstGroup.any((r) => r.text.contains(' & ')) ||
        conjunctions.any((conj) => firstGroup.any((r) => r.text.trim().toLowerCase() == conj.toLowerCase()));
    return hasArtistSignals ? groups : groups.skip(1).toList();
  }

  static List<Run> oddElements(List<Run> runsList) {
    final List<Run> result = [];
    for (var i = 0; i < runsList.length; i++) {
      if (i % 2 == 0) {
        result.add(runsList[i]);
      }
    }
    return result;
  }
}
