class GridRenderer {
  final List<dynamic>? items;

  GridRenderer({this.items});

  factory GridRenderer.fromJson(Map<String, dynamic> json) {
    return GridRenderer(
      items: json['items'] as List?,
    );
  }
}
