import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../theme/jarvis_theme.dart';
import '../widgets/arc_reactor.dart';
import '../widgets/chat_bubble.dart';
import 'settings_screen.dart';

const _uuid = Uuid();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showTextInput = false;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pingServer();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _pingServer() async {
    await JarvisApiService.instance.loadSettings();
    final online = await JarvisApiService.instance.ping();
    if (mounted) {
      context.read<ChatProvider>().setOnline(online);
      if (!online) {
        _addSystemMessage('⚠  Could not reach Jarvis server. Check Settings.');
      } else {
        _addSystemMessage('✦  Jarvis AI Online — Systems Nominal');
      }
    }
  }

  void _addSystemMessage(String content) {
    context.read<ChatProvider>().addMessage(ChatMessage(
          id: _uuid.v4(),
          content: content,
          role: MessageRole.system,
        ));
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _focusNode.unfocus();
    await _processUserInput(text);
  }

  Future<void> _processUserInput(String userText) async {
    final provider = context.read<ChatProvider>();

    provider.addMessage(ChatMessage(
      id: _uuid.v4(),
      content: userText,
      role: MessageRole.user,
    ));

    final jarvisId = _uuid.v4();
    provider.addMessage(ChatMessage(
      id: jarvisId,
      content: '',
      role: MessageRole.jarvis,
      status: MessageStatus.sending,
    ));
    provider.setThinking(true);
    _scrollToBottom();

    final response = await JarvisApiService.instance.sendText(userText);

    provider.updateLastJarvisMessage(
      response.reply,
      status: response.success ? MessageStatus.sent : MessageStatus.error,
    );
    provider.setThinking(false);
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    final provider = context.read<ChatProvider>();

    if (provider.isListening) {
      // ── STOP RECORDING ──────────────────────────────
      provider.setListening(false);
      _waveCtrl.stop();

      final path = await AudioService.instance.stopRecording();
      if (path == null) {
        _addSystemMessage('Recording failed. Please try again.');
        return;
      }

      provider.setThinking(true);

      // Add user placeholder — will be updated with transcript
      final userMsgId = _uuid.v4();
      provider.addMessage(ChatMessage(
        id: userMsgId,
        content: '🎙  Transcribing...',
        role: MessageRole.user,
      ));

      // Add Jarvis placeholder — will be updated with reply
      final jarvisPlaceholderId = _uuid.v4();
      provider.addMessage(ChatMessage(
        id: jarvisPlaceholderId,
        content: '',
        role: MessageRole.jarvis,
        status: MessageStatus.sending,
      ));
      _scrollToBottom();

      // Send audio to server → get transcript + reply
      final response = await JarvisApiService.instance.sendAudio(path);

      // Update user message with what was actually said
      provider.updateMessageById(
        userMsgId,
        response.transcript != null && response.transcript!.isNotEmpty
            ? response.transcript!
            : '🎙  (could not transcribe)',
      );

      // Update Jarvis message with his reply
      provider.updateMessageById(
        jarvisPlaceholderId,
        response.reply,
        status: response.success ? MessageStatus.sent : MessageStatus.error,
      );

      provider.setThinking(false);
      _scrollToBottom();
    } else {
      // ── START RECORDING ──────────────────────────────
      final started = await AudioService.instance.startRecording();
      if (started) {
        provider.setListening(true);
        _waveCtrl.repeat(reverse: true);
      } else {
        _addSystemMessage('⚠  Microphone permission denied.');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JarvisTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildReactorSection(),
            _buildChatArea(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ChatProvider>(
      builder: (_, provider, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: JarvisTheme.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'J.A.R.V.I.S',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: JarvisTheme.textPrimary,
                      letterSpacing: 5,
                    ),
                  ),
                  StatusIndicator(isOnline: provider.isOnline),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ).then((_) => _pingServer());
                },
                icon: const Icon(
                  Icons.tune,
                  color: JarvisTheme.textSecondary,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: () {
                  provider.clearHistory();
                  _addSystemMessage('✦  Memory cleared');
                },
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: JarvisTheme.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactorSection() {
    return Consumer<ChatProvider>(
      builder: (_, provider, __) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                JarvisTheme.bgDeep,
                JarvisTheme.bgSurface.withOpacity(0.3),
                JarvisTheme.bgDeep,
              ],
            ),
          ),
          child: Column(
            children: [
              ArcReactor(
                isListening: provider.isListening,
                isThinking: provider.isThinking,
                isOnline: provider.isOnline,
                size: 160,
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey(provider.isListening
                      ? 'l'
                      : provider.isThinking
                          ? 't'
                          : 'i'),
                  provider.isListening
                      ? '● RECORDING — TAP TO SEND'
                      : provider.isThinking
                          ? '◈ PROCESSING REQUEST...'
                          : 'READY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: provider.isListening
                        ? JarvisTheme.redAlert
                        : provider.isThinking
                            ? JarvisTheme.goldAccent
                            : JarvisTheme.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: Consumer<ChatProvider>(
        builder: (_, provider, __) {
          final messages = provider.messages;
          return ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: messages.length +
                (provider.isThinking &&
                        messages.isNotEmpty &&
                        messages.last.role != MessageRole.jarvis
                    ? 1
                    : 0),
            itemBuilder: (context, i) {
              if (i >= messages.length) return const ThinkingIndicator();
              final msg = messages[i];
              if (msg.role == MessageRole.jarvis &&
                  msg.status == MessageStatus.sending) {
                return const ThinkingIndicator();
              }
              return ChatBubble(message: msg);
            },
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<ChatProvider>(
      builder: (_, provider, __) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: JarvisTheme.bgDeep,
            border: Border(
              top: BorderSide(color: JarvisTheme.divider),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showTextInput) ...[
                _buildTextInput(),
                const SizedBox(height: 12),
              ],
              _buildActionRow(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: JarvisTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JarvisTheme.arcBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              style:
                  const TextStyle(color: JarvisTheme.textPrimary, fontSize: 15),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Type your command, sir...',
                hintStyle:
                    TextStyle(color: JarvisTheme.textDim, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          IconButton(
            onPressed: _sendText,
            icon: const Icon(Icons.send_rounded,
                color: JarvisTheme.arcBlue, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(ChatProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: _showTextInput ? Icons.keyboard_hide : Icons.keyboard,
          label: 'TYPE',
          color: JarvisTheme.goldAccent,
          onTap: () => setState(() => _showTextInput = !_showTextInput),
        ),
        const SizedBox(width: 24),
        // Big mic button
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isListening
                  ? JarvisTheme.redAlert
                  : JarvisTheme.arcBlue.withOpacity(0.15),
              border: Border.all(
                color: provider.isListening
                    ? JarvisTheme.redAlert
                    : JarvisTheme.arcBlue,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (provider.isListening
                          ? JarvisTheme.redAlert
                          : JarvisTheme.arcBlue)
                      .withOpacity(0.4),
                  blurRadius: provider.isListening ? 20 : 10,
                  spreadRadius: provider.isListening ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              provider.isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: JarvisTheme.textPrimary,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 24),
        _ActionButton(
          icon: Icons.memory,
          label: 'MEMORY',
          color: JarvisTheme.arcBlue,
          onTap: () => _showMemorySheet(),
        ),
      ],
    );
  }

  void _showMemorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: JarvisTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemorySheet(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemorySheet extends StatefulWidget {
  @override
  State<_MemorySheet> createState() => _MemorySheetState();
}

class _MemorySheetState extends State<_MemorySheet> {
  List<Map<String, dynamic>> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await JarvisApiService.instance.fetchMemory();
    setState(() {
      _memories = m;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: JarvisTheme.arcBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'JARVIS MEMORY',
                style: TextStyle(
                  color: JarvisTheme.arcBlue,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child:
                  CircularProgressIndicator(color: JarvisTheme.arcBlue),
            )
          else if (_memories.isEmpty)
            const Center(
              child: Text(
                'No memories stored yet.',
                style: TextStyle(color: JarvisTheme.textDim),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _memories.length,
                itemBuilder: (_, i) {
                  final m = _memories[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JarvisTheme.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: JarvisTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['timestamp']?.toString() ?? '',
                          style: const TextStyle(
                            color: JarvisTheme.textDim,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You: ${m['user'] ?? ''}',
                          style: const TextStyle(
                            color: JarvisTheme.goldAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Jarvis: ${m['reply'] ?? ''}',
                          style: const TextStyle(
                            color: JarvisTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}