import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/app_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart' as file_picker_lib;
import 'dart:io';
import 'package:lottie/lottie.dart';

class AICompanionChat extends ConsumerStatefulWidget {
  const AICompanionChat({super.key});

  @override
  ConsumerState<AICompanionChat> createState() => _AICompanionChatState();
}

class _AICompanionChatState extends ConsumerState<AICompanionChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Speech to Text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => debugPrint('onStatus: $val'),
      onError: (val) => debugPrint('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _lastWords = val.recognizedWords;
          if (_lastWords.isNotEmpty) {
            _messageController.text = _lastWords;
          }
        }),
        localeId: 'ar_SA',
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickFile() async {
    final provider = ref.read(appRiverpod);
    final file_picker_lib.FilePickerResult? result =
        await file_picker_lib.FilePicker.platform.pickFiles(
      type: file_picker_lib.FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null) {
      String? path = result.files.single.path;
      String? name = result.files.single.name;
      String type =
          name.endsWith('jpg') || name.endsWith('png') ? 'image' : 'file';

      provider.sendCompanionMessage('', mediaPath: path, mediaType: type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    // Scroll only when the chat history length changes, not on every rebuild
    ref.listen<AppRiverpod>(appRiverpod, (previous, next) {
      if (previous?.companionChatHistory.length !=
          next.companionChatHistory.length) {
        _scrollToBottom();
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFEEF2FF),
            Color(0xFFF1F5F9),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          // Header - Professional Design
          _buildHeader(context),

          // Chat Messages
          Expanded(
            child: Stack(
              children: [
                // Animated-like Background Blobs
                Positioned(
                  top: 40,
                  left: -30,
                  child: _buildBackgroundBlob(
                      120, const Color(0xFF6366F1).withValues(alpha: 0.08)),
                ),
                Positioned(
                  bottom: 100,
                  right: -40,
                  child: _buildBackgroundBlob(
                      180, const Color(0xFF8B5CF6).withValues(alpha: 0.08)),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3,
                  right: 20,
                  child: _buildBackgroundBlob(
                      60, const Color(0xFFEC4899).withValues(alpha: 0.05)),
                ),

                ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: provider.companionChatHistory.length +
                      (provider.isAiThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (provider.isAiThinking &&
                        index == provider.companionChatHistory.length) {
                      return _buildTypingIndicator();
                    }
                    final msg = provider.companionChatHistory[index];
                    return _buildChatBubble(msg);
                  },
                ),
              ],
            ),
          ),

          // Quick Replies
          _buildQuickReplies(provider),

          // Input Area - Multi-functional
          _buildInputArea(provider),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              // Bot Animation replaces the Icon/Title
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Lottie.asset(
                      'assets/animations/Robot.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.smart_toy_rounded,
                          color: Color(0xFF6366F1),
                          size: 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                ref.watch(appRiverpod).lastAiMode == 'bedrock'
                                    ? Colors.green
                                    : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ref.watch(appRiverpod).lastAiMode == 'bedrock'
                              ? 'متصل بـ AWS Bedrock'
                              : 'وضع محلي',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Claude Haiku · AWS',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    size: 28, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'أنا هنا للاستماع إليك في أي وقت 💬',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF92400E),
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            width: 36,
            height: 36,
            child: Lottie.asset(
              'assets/animations/Robot.json',
              repeat: true,
              errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy_rounded,
                  color: Color(0xFF6366F1), size: 28),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
                SizedBox(width: 10),
                Text(
                  'يفكر...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(CompanionMessage msg) {
    final isAI = msg.isFromAI;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              width: 36,
              height: 36,
              child: Lottie.asset(
                'assets/animations/Robot.json',
                repeat: true,
              ),
            ),
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment:
                  isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                if (msg.mediaPath != null) _buildMediaPreview(msg),
                if (msg.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isAI
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isAI ? Colors.white : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft:
                            isAI ? Radius.zero : const Radius.circular(24),
                        bottomRight:
                            isAI ? const Radius.circular(24) : Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAI
                              ? Colors.black.withValues(alpha: 0.05)
                              : const Color(0xFF6366F1).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isAI ? FontWeight.w500 : FontWeight.bold,
                        color: isAI ? const Color(0xFF334155) : Colors.white,
                        fontFamily: 'Cairo',
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isAI)
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 14, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(CompanionMessage msg) {
    if (msg.mediaType == 'image' && msg.mediaPath != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(msg.mediaPath!),
            width: 200,
            height: 150,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (msg.mediaType == 'file') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_rounded, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text(
              'ملف مرفق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuickReplies(AppRiverpod provider) {
    final replies = [
      {'text': 'أشعر بالوحدة 😔', 'color': const Color(0xFFE0E7FF)},
      {'text': 'أنا سعيد اليوم! 😊', 'color': const Color(0xFFDCFCE7)},
      {'text': 'هل يمكنك مساعدتي؟ 🤔', 'color': const Color(0xFFFEF3C7)},
      {'text': 'أريد الحديث فقط 🗣️', 'color': const Color(0xFFF1F5F9)}
    ];
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ActionChip(
              label: Text(reply['text'] as String,
                  style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: (reply['color'] as Color).withValues(alpha: 1.0) ==
                              const Color(0xFFF1F5F9)
                          ? const Color(0xFF475569)
                          : const Color(0xFF1E293B))),
              onPressed: () =>
                  provider.sendCompanionMessage(reply['text'] as String),
              backgroundColor: reply['color'] as Color,
              side: BorderSide(
                  color: (reply['color'] as Color).withValues(alpha: 0.5),
                  width: 1),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(AppRiverpod provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice Button - Premium Style
          _buildActionButton(
            icon: _isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
            gradient: _isListening
                ? const LinearGradient(colors: [Colors.redAccent, Colors.red])
                : const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            iconColor: Colors.white,
            isPulse: _isListening,
            onTap: _isListening ? _stopListening : _startListening,
          ),
          const SizedBox(width: 10),
          // Attach File Button
          _buildActionButton(
            icon: Icons.attach_file_rounded,
            color: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF64748B),
            onTap: _pickFile,
          ),
          const SizedBox(width: 12),
          // Input Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Cairo'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_messageController.text.isNotEmpty) {
                        provider.sendCompanionMessage(_messageController.text);
                        _messageController.clear();
                      }
                    },
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFF6366F1), size: 28),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required VoidCallback onTap,
      Color? color,
      Gradient? gradient,
      Color? iconColor,
      bool isPulse = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? const Color(0xFFF1F5F9)) : null,
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: isPulse
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 4,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child:
            Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 24),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF6366F1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
