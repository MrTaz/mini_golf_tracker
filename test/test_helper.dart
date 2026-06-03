import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({})!;
    }
    if (key == 'AssetManifest.json') {
      final manifest = {
        "assets/images/rank1.png": ["assets/images/rank1.png"],
        "assets/images/rank2.png": ["assets/images/rank2.png"],
        "assets/images/rank3.png": ["assets/images/rank3.png"],
        "assets/images/mini_golf_placeholder.png": [
          "assets/images/mini_golf_placeholder.png"
        ],
        "assets/images/loggedin_background_2.png": [
          "assets/images/loggedin_background_2.png"
        ],
        "assets/images/background.jpeg": [
          "assets/images/background.jpeg"
        ],
        "assets/images/avatars_3d_avatar_28.png": [
          "assets/images/avatars_3d_avatar_28.png"
        ],
      };
      return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(jsonEncode(manifest))));
    }
    if (key.endsWith('.png') ||
        key.endsWith('.jpg') ||
        key.endsWith('.jpeg') ||
        key.endsWith('.gif')) {
      return ByteData.sublistView(Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]));
    }
    throw FlutterError('Asset not found: $key');
  }
}
