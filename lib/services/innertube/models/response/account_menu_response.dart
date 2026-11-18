class AccountMenuResponse {
  final List<AccountMenuAction>? actions;

  AccountMenuResponse({this.actions});

  factory AccountMenuResponse.fromJson(Map<String, dynamic> json) {
    return AccountMenuResponse(
      actions: (json['actions'] as List?)
          ?.map((e) => AccountMenuAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AccountMenuAction {
  final OpenPopupAction? openPopupAction;

  AccountMenuAction({this.openPopupAction});

  factory AccountMenuAction.fromJson(Map<String, dynamic> json) {
    return AccountMenuAction(
      openPopupAction: json['openPopupAction'] != null
          ? OpenPopupAction.fromJson(json['openPopupAction'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OpenPopupAction {
  final PopupMenu? popup;

  OpenPopupAction({this.popup});

  factory OpenPopupAction.fromJson(Map<String, dynamic> json) {
    return OpenPopupAction(
      popup: json['popup'] != null
          ? PopupMenu.fromJson(json['popup'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PopupMenu {
  final MultiPageMenuRenderer? multiPageMenuRenderer;

  PopupMenu({this.multiPageMenuRenderer});

  factory PopupMenu.fromJson(Map<String, dynamic> json) {
    return PopupMenu(
      multiPageMenuRenderer: json['multiPageMenuRenderer'] != null
          ? MultiPageMenuRenderer.fromJson(
              json['multiPageMenuRenderer'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MultiPageMenuRenderer {
  final AccountHeader? header;

  MultiPageMenuRenderer({this.header});

  factory MultiPageMenuRenderer.fromJson(Map<String, dynamic> json) {
    return MultiPageMenuRenderer(
      header: json['header'] != null
          ? AccountHeader.fromJson(json['header'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AccountHeader {
  final ActiveAccountHeaderRenderer? activeAccountHeaderRenderer;

  AccountHeader({this.activeAccountHeaderRenderer});

  factory AccountHeader.fromJson(Map<String, dynamic> json) {
    return AccountHeader(
      activeAccountHeaderRenderer: json['activeAccountHeaderRenderer'] != null
          ? ActiveAccountHeaderRenderer.fromJson(
              json['activeAccountHeaderRenderer'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActiveAccountHeaderRenderer {
  final String? accountName;
  final String? email;
  final String? channelHandle;
  final String? thumbnailUrl;

  ActiveAccountHeaderRenderer({
    this.accountName,
    this.email,
    this.channelHandle,
    this.thumbnailUrl,
  });

  factory ActiveAccountHeaderRenderer.fromJson(Map<String, dynamic> json) {
    final runsName = json['accountName']?['runs'] as List?;
    final runsEmail = json['email']?['runs'] as List?;
    final runsHandle = json['channelHandle']?['runs'] as List?;
    final thumbs = json['accountPhoto']?['thumbnails'] as List?;

    return ActiveAccountHeaderRenderer(
      accountName: runsName != null && runsName.isNotEmpty ? runsName.first['text'] : null,
      email: runsEmail != null && runsEmail.isNotEmpty ? runsEmail.first['text'] : null,
      channelHandle: runsHandle != null && runsHandle.isNotEmpty ? runsHandle.first['text'] : null,
      thumbnailUrl: thumbs != null && thumbs.isNotEmpty ? thumbs.last['url'] : null,
    );
  }
}
