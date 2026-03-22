import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import '../theme/jarvis_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool animate;

  const ChatBubble({
    super.key,
    required this.message,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) return _buildSystemMessage();

    Widget bubble = Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Text(
              isUser ? 'YOU  ${message.timeStr}' : 'JARVIS  ${message.timeStr}',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: isUser ? JarvisTheme.goldAccent : JarvisTheme.arcBlueDim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? JarvisTheme.goldAccent.withOpacity(0.12)
                  : JarvisTheme.bgCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(
                color: isUser
                    ? JarvisTheme.goldAccent.withOpacity(0.3)
                    : JarvisTheme.arcBlue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? JarvisTheme.goldAccent.withOpacity(0.05)
                      : JarvisTheme.arcBlue.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.status == MessageStatus.error)
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: JarvisTheme.redAlert),
                      const SizedBox(width: 6),
                      Text(
                        'CONNECTION ERROR',
                        style: TextStyle(
                          fontSize: 10,
                          color: JarvisTheme.redAlert,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: message.status == MessageStatus.error
                        ? JarvisTheme.redAlert
                        : JarvisTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (animate) {
      bubble = bubble
          .animate()
          .slideX(
            begin: isUser ? 0.3 : -0.3,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOut,
          )
          .fadeIn(duration: 250.ms);
    }

    return bubble;
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: JarvisTheme.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: JarvisTheme.divider),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 11,
              color: JarvisTheme.textDim,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thinking indicator - animated dots
class ThinkingIndicator extends StatelessWidget {
  const ThinkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 60, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'JARVIS  PROCESSING',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: JarvisTheme.arcBlueDim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: JarvisTheme.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: JarvisTheme.arcBlue.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: JarvisTheme.arcBlue,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      delay: Duration(milliseconds: i * 200),
                      duration: 400.ms,
                    )
                    .then()
                    .scale(
                      end: const Offset(0.5, 0.5),
                      duration: 400.ms,
                    );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
