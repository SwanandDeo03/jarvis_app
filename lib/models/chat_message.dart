import 'package:flutter/material.dart';

enum MessageRole { user, jarvis, system }
enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final String? audioPath;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.audioPath,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      status: status ?? this.status,
      audioPath: audioPath,
    );
  }

  String get timeStr {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;
  bool _isListening = false;
  bool _isOnline = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isThinking => _isThinking;
  bool get isListening => _isListening;
  bool get isOnline => _isOnline;

  void addMessage(ChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  void updateLastJarvisMessage(String content, {MessageStatus? status}) {
    final idx = _messages.lastIndexWhere((m) => m.role == MessageRole.jarvis);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(content: content, status: status);
      notifyListeners();
    }
  }

  void updateMessageById(String id, String content, {MessageStatus? status}) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(
        content: content,
        status: status ?? _messages[idx].status,
      );
      notifyListeners();
    }
  }

  void setThinking(bool v) {
    _isThinking = v;
    notifyListeners();
  }

  void setListening(bool v) {
    _isListening = v;
    notifyListeners();
  }

  void setOnline(bool v) {
    _isOnline = v;
    notifyListeners();
  }

  void clearHistory() {
    _messages.clear();
    notifyListeners();
  }
}