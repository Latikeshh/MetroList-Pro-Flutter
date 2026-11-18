class Badge {
  final String label;

  Badge({required this.label});

  factory Badge.fromJson(Map<String, dynamic> json) {
    final runs = json['musicInlineBadgeRenderer']?['accessibilityData']?['accessibilityData']?['label'] as String?
        ?? json['musicInlineBadgeRenderer']?['icon']?['iconType'] as String?
        ?? '';
    return Badge(label: runs);
  }
}
