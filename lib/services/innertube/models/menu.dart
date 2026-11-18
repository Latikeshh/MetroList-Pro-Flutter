library;

import 'navigation_endpoint.dart';
import 'runs.dart';

class Icon {
  final String? iconType;

  const Icon({this.iconType});

  factory Icon.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Icon();
    return Icon(iconType: json['iconType']?.toString());
  }
}

class MenuNavigationItemRenderer {
  final Runs text;
  final Icon? icon;
  final NavigationEndpoint? navigationEndpoint;

  const MenuNavigationItemRenderer({
    required this.text,
    this.icon,
    this.navigationEndpoint,
  });

  factory MenuNavigationItemRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MenuNavigationItemRenderer(text: const Runs(runs: []));
    return MenuNavigationItemRenderer(
      text: Runs.fromJson(json['text']),
      icon: json['icon'] is Map<String, dynamic> ? Icon.fromJson(json['icon']) : null,
      navigationEndpoint: json['navigationEndpoint'] is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(json['navigationEndpoint'])
          : null,
    );
  }
}

class MenuServiceItemRenderer {
  final Runs text;
  final Icon? icon;
  final NavigationEndpoint? serviceEndpoint;

  const MenuServiceItemRenderer({
    required this.text,
    this.icon,
    this.serviceEndpoint,
  });

  factory MenuServiceItemRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MenuServiceItemRenderer(text: const Runs(runs: []));
    return MenuServiceItemRenderer(
      text: Runs.fromJson(json['text']),
      icon: json['icon'] is Map<String, dynamic> ? Icon.fromJson(json['icon']) : null,
      serviceEndpoint: json['serviceEndpoint'] is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(json['serviceEndpoint'])
          : null,
    );
  }
}

class ToggleMenuServiceRenderer {
  final Icon? defaultIcon;
  final DefaultServiceEndpoint? defaultServiceEndpoint;
  final ToggledServiceEndpoint? toggledServiceEndpoint;
  final bool isSelected;

  const ToggleMenuServiceRenderer({
    this.defaultIcon,
    this.defaultServiceEndpoint,
    this.toggledServiceEndpoint,
    this.isSelected = false,
  });

  factory ToggleMenuServiceRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ToggleMenuServiceRenderer();
    return ToggleMenuServiceRenderer(
      defaultIcon: json['defaultIcon'] is Map<String, dynamic>
          ? Icon.fromJson(json['defaultIcon'])
          : null,
      defaultServiceEndpoint: json['defaultServiceEndpoint'] is Map<String, dynamic>
          ? DefaultServiceEndpoint.fromJson(json['defaultServiceEndpoint'])
          : null,
      toggledServiceEndpoint: json['toggledServiceEndpoint'] is Map<String, dynamic>
          ? ToggledServiceEndpoint.fromJson(json['toggledServiceEndpoint'])
          : null,
      isSelected: json['isSelected'] == true,
    );
  }
}

class MenuItem {
  final MenuNavigationItemRenderer? menuNavigationItemRenderer;
  final MenuServiceItemRenderer? menuServiceItemRenderer;
  final ToggleMenuServiceRenderer? toggleMenuServiceItemRenderer;

  const MenuItem({
    this.menuNavigationItemRenderer,
    this.menuServiceItemRenderer,
    this.toggleMenuServiceItemRenderer,
  });

  factory MenuItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MenuItem();
    return MenuItem(
      menuNavigationItemRenderer: json['menuNavigationItemRenderer'] is Map<String, dynamic>
          ? MenuNavigationItemRenderer.fromJson(json['menuNavigationItemRenderer'])
          : null,
      menuServiceItemRenderer: json['menuServiceItemRenderer'] is Map<String, dynamic>
          ? MenuServiceItemRenderer.fromJson(json['menuServiceItemRenderer'])
          : null,
      toggleMenuServiceItemRenderer: json['toggleMenuServiceItemRenderer'] is Map<String, dynamic>
          ? ToggleMenuServiceRenderer.fromJson(json['toggleMenuServiceItemRenderer'])
          : null,
    );
  }
}

class TopLevelButton {
  final Icon? icon;
  final NavigationEndpoint? navigationEndpoint;

  const TopLevelButton({
    this.icon,
    this.navigationEndpoint,
  });

  factory TopLevelButton.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TopLevelButton();
    final btn = json['buttonRenderer'];
    if (btn is Map<String, dynamic>) {
      return TopLevelButton(
        icon: btn['icon'] is Map<String, dynamic> ? Icon.fromJson(btn['icon']) : null,
        navigationEndpoint: btn['navigationEndpoint'] is Map<String, dynamic>
            ? NavigationEndpoint.fromJson(btn['navigationEndpoint'])
            : null,
      );
    }
    return const TopLevelButton();
  }
}

class Menu {
  final List<MenuItem>? items;
  final List<TopLevelButton>? topLevelButtons;

  const Menu({
    this.items,
    this.topLevelButtons,
  });

  factory Menu.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Menu();
    final renderer = json['menuRenderer'];
    if (renderer is Map<String, dynamic>) {
      final rawItems = renderer['items'];
      final rawTop = renderer['topLevelButtons'];
      return Menu(
        items: rawItems is List
            ? rawItems.whereType<Map<String, dynamic>>().map(MenuItem.fromJson).toList()
            : null,
        topLevelButtons: rawTop is List
            ? rawTop.whereType<Map<String, dynamic>>().map(TopLevelButton.fromJson).toList()
            : null,
      );
    }
    return const Menu();
  }
}
