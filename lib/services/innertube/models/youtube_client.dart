library;

enum YouTubeClientName {
  webRemix(
    'WEB_REMIX',
    '1.20260707.12.00',
    '67',
    'https://music.youtube.com/youtubei/v1',
    loginSupported: true,
    useSignatureTimestamp: true,
  ),
  web(
    'WEB',
    '2.20260708.00.00',
    '1',
    'https://www.youtube.com/youtubei/v1',
    loginSupported: true,
    useSignatureTimestamp: true,
  ),
  androidMusic(
    'ANDROID_MUSIC',
    '5.34.51',
    '21',
    'https://music.youtube.com/youtubei/v1',
    osName: 'Android',
    osVersion: '11',
    androidSdkVersion: '30',
    includeUserAgentInContext: true,
  ),
  ios(
    'IOS',
    '21.26.4',
    '5',
    'https://www.youtube.com/youtubei/v1',
    osName: 'iPhone',
    osVersion: '18.3.2.22D82',
    deviceMake: 'Apple',
    deviceModel: 'iPhone16,2',
    includeUserAgentInContext: true,
  ),
  tvHtml5(
    'TVHTML5',
    '7.20260707.07.00',
    '7',
    'https://www.youtube.com/youtubei/v1',
    loginSupported: true,
    includeUserAgentInContext: true,
    useSignatureTimestamp: true,
  ),
  androidVr(
    'ANDROID_VR',
    '1.65.10',
    '28',
    'https://www.youtube.com/youtubei/v1',
    osName: 'Android',
    osVersion: '12L',
    deviceMake: 'Oculus',
    deviceModel: 'Quest 3',
    androidSdkVersion: '32',
    includeUserAgentInContext: true,
    useMusicPlayerEndpoint: true,
  );

  final String clientName;
  final String clientVersion;
  final String clientNameHeader;
  final String endpointUrl;
  final String? osName;
  final String? osVersion;
  final String? deviceMake;
  final String? deviceModel;
  final String? androidSdkVersion;
  final bool loginSupported;
  final bool includeUserAgentInContext;
  final bool useSignatureTimestamp;
  final bool isEmbedded;
  final bool useMusicPlayerEndpoint;

  const YouTubeClientName(
    this.clientName,
    this.clientVersion,
    this.clientNameHeader,
    this.endpointUrl, {
    this.osName,
    this.osVersion,
    this.deviceMake,
    this.deviceModel,
    this.androidSdkVersion,
    this.loginSupported = false,
    this.includeUserAgentInContext = false,
    this.useSignatureTimestamp = false,
    this.isEmbedded = false,
    this.useMusicPlayerEndpoint = false,
  });
}

class YouTubeClient {
  final YouTubeClientName client;
  final String userAgent;

  const YouTubeClient({
    required this.client,
    required this.userAgent,
  });

  static const String webUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0';

  static const YouTubeClient webRemix = YouTubeClient(
    client: YouTubeClientName.webRemix,
    userAgent: webUserAgent,
  );

  static const YouTubeClient web = YouTubeClient(
    client: YouTubeClientName.web,
    userAgent: webUserAgent,
  );

  static const YouTubeClient androidMusic = YouTubeClient(
    client: YouTubeClientName.androidMusic,
    userAgent:
        'com.google.android.apps.youtube.music/5.34.51 (Linux; U; Android 11) gzip',
  );

  static const YouTubeClient ios = YouTubeClient(
    client: YouTubeClientName.ios,
    userAgent:
        'com.google.ios.youtube/21.26.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
  );

  static const YouTubeClient tvHtml5 = YouTubeClient(
    client: YouTubeClientName.tvHtml5,
    userAgent:
        'Mozilla/5.0 (ChromiumStylePlatform) Cobalt/25.lts.30.1034943-gold (unlike Gecko), Unknown_TV_Unknown_0/Unknown (Unknown, Unknown)',
  );

  static const YouTubeClient androidVr = YouTubeClient(
    client: YouTubeClientName.androidVr,
    userAgent:
        'com.google.android.apps.youtube.vr.oculus/1.65.10 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
  );
}
