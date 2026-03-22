import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class JarvisApiService {
  static JarvisApiService? _instance;
  static JarvisApiService get instance => _instance ??= JarvisApiService._();

  JarvisApiService._() {
    // Force audio through speaker on Android
    _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {},
        ),
      ),
    );
  }

  String _baseUrl = 'http://192.168.1.6:8000';
  final AudioPlayer _player = AudioPlayer();

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_url') ?? 'http://192.168.1.6:8000';
  }

  Future<void> saveSettings(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
  }

  String get baseUrl => _baseUrl;

  /// Play Jarvis voice response
  Future<void> playAudio(String audioId) async {
    try {
      final url = '$_baseUrl/audio/$audioId';
      debugPrint('🔊 Fetching audio: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      debugPrint('🔊 Status: ${response.statusCode}, bytes: ${response.bodyBytes.length}');

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/jarvis_reply_$audioId.wav');
        await file.writeAsBytes(response.bodyBytes);

        await _player.stop();
        await _player.setVolume(1.0);
        await _player.play(DeviceFileSource(file.path));

        debugPrint('🔊 Playback started!');
      }
    } catch (e) {
      debugPrint('🔊 Audio error: $e');
    }
  }

  /// Send text query to Jarvis
  Future<JarvisResponse> sendText(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ask'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': message}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioId = data['audio_id'];
        debugPrint('📩 audio_id: $audioId');
        if (audioId != null) playAudio(audioId);
        return JarvisResponse(
          success: true,
          reply: data['reply'] ?? data['response'] ?? 'No response',
          audioId: audioId,
        );
      } else {
        return JarvisResponse(
          success: false,
          reply: 'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException {
      return JarvisResponse(
        success: false,
        reply: 'Cannot reach Jarvis. Check your server IP in Settings.',
      );
    } catch (e) {
      return JarvisResponse(success: false, reply: 'Error: $e');
    }
  }

  /// Send audio to Jarvis
  Future<JarvisResponse> sendAudio(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/voice'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('audio', filePath),
      );
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioId = data['audio_id'];
        debugPrint('📩 voice audio_id: $audioId');
        if (audioId != null) playAudio(audioId);
        return JarvisResponse(
          success: true,
          reply: data['reply'] ?? data['response'] ?? '',
          transcript: data['transcript'] ?? data['you'] ?? '',
          audioId: audioId,
        );
      } else {
        return JarvisResponse(
          success: false,
          reply: 'Server error: ${response.statusCode}',
        );
      }
    } on SocketException {
      return JarvisResponse(
        success: false,
        reply: 'Cannot reach Jarvis. Check your server IP in Settings.',
      );
    } catch (e) {
      return JarvisResponse(success: false, reply: 'Error: $e');
    }
  }

  /// Health check
  Future<bool> ping() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ping'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch memory
  Future<List<Map<String, dynamic>>> fetchMemory() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/memory'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['memories'] ?? []);
      }
    } catch (_) {}
    return [];
  }
}

class JarvisResponse {
  final bool success;
  final String reply;
  final String? transcript;
  final String? audioId;

  JarvisResponse({
    required this.success,
    required this.reply,
    this.transcript,
    this.audioId,
  });
}