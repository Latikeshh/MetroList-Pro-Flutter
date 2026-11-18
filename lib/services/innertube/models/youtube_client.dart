library;

enum YouTubeClientName {
  webRemix('WEB_REMIX', '1.20260707.12.00', '67', 'https://music.youtube.com/youtubei/v1'),
  web('WEB', '2.20260708.00.00', '1', 'https://www.youtube.com/youtubei/v1'),
  androidMusic('ANDROID_MUSIC', '6.42.52', '61', 'https://music.youtube.com/youtubei/v1'),
  ios('IOS', '19.29.1', '5', 'https://www.youtube.com/youtubei/v1'),
  tvHtml5('TVHTML5_SIMPLY_EMBEDDED_PLAYER', '2.0', '85', 'https://www.youtube.com/youtubei/v1'),
  androidVr('ANDROID_VR', '1.57.2', '28', 'https://www.youtube.com/youtubei/v1');

  final String clientName;
  final String clientVersion;
  final String clientNameHeader;
  final String endpointUrl;

  const YouTubeClientName(
    this.clientName,
    this.clientVersion,
    this.clientNameHeader,
    this.endpointUrl,
  );
}

class YouTubeClient {
  final YouTubeClientName client;
  final String userAgent;

  const YouTubeClient({
    required this.client,
    required this.userAgent,
  });

  static const YouTubeClient webRemix = YouTubeClient(
    client: YouTubeClientName.webRemix,
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
  );

  static const YouTubeClient web = YouTubeClient(
    client: YouTubeClientName.web,
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
  );

  static const YouTubeClient androidMusic = YouTubeClient(
    client: YouTubeClientName.androidMusic,
    userAgent:
        'com.google.android.apps.youtube.music/6.42.52 (Linux; U; Android 14; en_US)',
  );

  static const YouTubeClient ios = YouTubeClient(
    client: YouTubeClientName.ios,
    userAgent:
        'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X; en_US)',
  );

  static const YouTubeClient tvHtml5 = YouTubeClient(
    client: YouTubeClientName.tvHtml5,
    userAgent:
        'Mozilla/5.0 (SmartHub; SMART-TV; U; Linux/SmartTV) AppleWebKit/537.42 SmartTV Safari/537.42',
  );

  static const YouTubeClient androidVr = YouTubeClient(
    client: YouTubeClientName.androidVr,
    userAgent:
        'com.google.android.apps.youtube.vr.oculus/1.57.2 (Linux; U; Android 12)',
  );
}
