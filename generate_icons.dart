import 'dart:io';
import 'dart:convert';

void main() {
  // Create a simple icon configuration
  final iconConfig = {
    "flutter_launcher_icons": {
      "android": true,
      "ios": true,
      "image_path": "assets/icon/icon.png",
      "min_sdk_android": 21,
      "web": {
        "generate": true,
        "image_path": "assets/icon/icon.png",
        "background_color": "#2E7D32",
        "theme_color": "#4CAF50",
      },
      "windows": {
        "generate": true,
        "image_path": "assets/icon/icon.png",
        "icon_size": 48,
      },
      "macos": {"generate": true, "image_path": "assets/icon/icon.png"},
      "linux": {"generate": true, "image_path": "assets/icon/icon.png"},
    },
  };

  // Write the configuration to pubspec.yaml
  final pubspecPath = 'pubspec.yaml';
  final pubspecContent = File(pubspecPath).readAsStringSync();

  // Add flutter_launcher_icons configuration if not already present
  if (!pubspecContent.contains('flutter_launcher_icons:')) {
    final newContent = pubspecContent + '\n\n' + json.encode(iconConfig);
    File(pubspecPath).writeAsStringSync(newContent);
    print('Added flutter_launcher_icons configuration to pubspec.yaml');
  } else {
    print(
      'flutter_launcher_icons configuration already exists in pubspec.yaml',
    );
  }

  print('Icon generation configuration created!');
  print(
    'To generate icons, run: flutter pub get && flutter pub run flutter_launcher_icons:main',
  );
}
