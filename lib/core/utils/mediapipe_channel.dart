import 'package:flutter/services.dart';

class MediaPipeChannel {
  static const MethodChannel _channel =
      MethodChannel('signspeak/mediapipe');

  static Future<String> loadMediaPipe() async {
    final result = await _channel.invokeMethod<String>('loadMediaPipe');
    return result ?? 'Sin respuesta';
  }

  static Future<String> detectHandFromImage(String imagePath) async {
    final result = await _channel.invokeMethod<String>(
      'detectHandFromImage',
      {
        'imagePath': imagePath,
      },
    );
    return result ?? 'Sin respuesta';
  }
}