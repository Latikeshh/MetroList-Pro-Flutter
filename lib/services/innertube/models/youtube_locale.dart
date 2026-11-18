library;

class YouTubeLocale {
  final String hl;
  final String gl;

  const YouTubeLocale({
    this.hl = 'en',
    this.gl = 'US',
  });

  Map<String, String> toMap() => {
        'hl': hl,
        'gl': gl,
      };

  static const YouTubeLocale defaultLocale = YouTubeLocale(hl: 'en', gl: 'US');
}
