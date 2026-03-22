import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  FlutterSoundRecorder? _recorder;
  String? _currentPath;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    debugPrint('Mic permission: ${status.isGranted}');
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('No mic permission!');
      return false;
    }

    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      final dir = await getTemporaryDirectory();
      _currentPath = '${dir.path}/jarvis_input.aac';

      debugPrint('Starting recorder to: $_currentPath');

      await _recorder!.startRecorder(
        toFile: _currentPath,
        codec: Codec.aacADTS,
      );

      debugPrint('Recorder started: ${_recorder!.isRecording}');
      return true;
    } catch (e) {
      debugPrint('startRecording error: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      debugPrint('Stopping recorder...');
      final path = await _recorder!.stopRecorder();
      await _recorder!.closeRecorder();
      _recorder = null;

      final file = File(path ?? _currentPath ?? '');
      final size = await file.exists() ? await file.length() : 0;
      debugPrint('Recording stopped. File: $path, size: $size bytes');

      return path ?? _currentPath;
    } catch (e) {
      debugPrint('stopRecording error: $e');
      return _currentPath;
    }
  }

  bool get isRecording => _recorder?.isRecording ?? false;
}