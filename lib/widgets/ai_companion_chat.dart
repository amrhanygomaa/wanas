import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/app_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart' as file_picker_lib;
import 'dart:io';
import 'package:lottie/lottie.dart';
import 'dart:ui';

class AICompanionChat extends ConsumerStatefulWidget {
  const AICompanionChat({super.key});

  @override
  ConsumerState<AICompanionChat> createState() => _AICompanionChatState();
}

class _AICompanionChatState extends ConsumerState<AICompanionChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _pickFile() async {
    final provider = ref.read(appRiverpod);
    final file_picker_lib.FilePickerResult? result =
        await file_picker_lib.FilePicker.platform.pickFiles(
      type: file_picker_lib.FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null) {
      String? path = result.files.single.path;
      String name = result.files.single.name;
      String type =
          name.endsWith('jpg') || name.endsWith('png')
              ? 'image'
              : 'file';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF8FAFC),
                const Color(0xFFEEF2FF),
                const Color(0xFFF1F5F9),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header - Professional Design
              _buildHeader(context),
    
              // Chat Messages
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
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
                        itemCount: provider.companionChatHistory.length,
                        itemBuilder: (context, index) {
                          final msg = provider.companionChatHistory[index];
                          return _buildChatBubble(msg);
                        },
                      ),
                    ],
                  ),
                ),
              ),
    
              // Input Area - Multi-functional
              _buildInputArea(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 14,
        bottom: 14,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bot Animation - Premium circle container
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 62,
                height: 62,
                child: Lottie.asset(
                  'assets/animations/Robot.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.smart_toy_rounded,
                          color: Color(0xFF8B5CF6), size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'رفيقي الذكي',
                      style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'نشط الآن',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Back Button on the Left (pointing left)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Color(0xFF64748B)),
              ),
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
                              ? Colors.black.withOpacity(0.05)
                              : const Color(0xFF6366F1).withOpacity(0.2),
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
                color: const Color(0xFF64748B).withOpacity(0.1),
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
              color: Colors.black.withOpacity(0.1),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_rounded, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              'ملف مرفق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInputArea(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice Button - Premium Style
          _buildActionButton(
            icon: Icons.mic_none_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            iconColor: Colors.white,
            isPulse: false,
            onTap: () async {
              FocusScope.of(context).unfocus();
              final String? result = await Navigator.push<String>(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const VoiceAssistantScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );

              if (result != null && result.trim().isNotEmpty) {
                provider.sendCompanionMessage(result.trim());
                _scrollToBottom();
              }
            },
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
                      focusNode: _focusNode,
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
                        _scrollToBottom();
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
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 4,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  String _wordsSpoken = '';
  String _statusText = 'جاري التهيئة...';
  bool _isPopping = false; // Prevents multiple Pops

  @override
  void initState() {
    super.initState();
    // 1. Initialize Glow Animation for Siri/Jarvis pulsating effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // 2. Initialize Speech engine with a small delay for smoother screen transitions
    _speech = stt.SpeechToText();
    Future.delayed(const Duration(milliseconds: 350), _initSpeech);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (!mounted) return;
          print('Speech Status: $val');
          if (val == 'listening') {
            setState(() {
              _isListening = true;
              _statusText = 'أنا أستمع إليك...';
            });
          } else if (val == 'notListening') {
            setState(() {
              _isListening = false;
              if (_wordsSpoken.isEmpty) {
                _statusText = 'اضغط على الأورب لبدء التحدث';
              } else {
                _statusText = 'تم التقاط الصوت بنجاح';
              }
            });
            // Auto submit!
            if (_wordsSpoken.isNotEmpty && !_isPopping) {
              _isPopping = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context, _wordsSpoken);
                }
              });
            }
          }
        },
        onError: (val) {
          if (!mounted) return;
          print('Speech Error: $val');
          setState(() {
            _isListening = false;
            _statusText = 'اضغط للبدء أو حاول مجدداً';
          });
        },
      );

      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
          if (available) {
            _startListening();
          } else {
            _statusText = 'التعرف على الصوت غير متاح';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'خطأ في تهيئة الميكروفون';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_isSpeechAvailable) return;
    
    setState(() {
      _wordsSpoken = '';
      _isListening = true;
      _statusText = 'أستمع الآن...';
    });

    await _speech.listen(
      onResult: (val) {
        if (!mounted) return;
        setState(() {
          _wordsSpoken = val.recognizedWords;
          if (_wordsSpoken.isNotEmpty) {
            _statusText = 'جاري الكتابة...';
          }
        });
      },
      localeId: 'ar_SA',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      // Auto submit on manual stop if something was spoken
      if (_wordsSpoken.isNotEmpty && !_isPopping) {
        _isPopping = true;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.pop(context, _wordsSpoken);
          }
        });
      }
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Premium Glassmorphic Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      const Color(0xFF1E1B4B).withOpacity(0.85), // Premium deep indigo
                      Colors.black.withOpacity(0.92),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top header controls (Back/Cancel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status dot indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isListening
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isListening ? const Color(0xFF10B981) : Colors.amber,
                                shape: BoxShape.circle,
                                boxShadow: _isListening
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.6),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isListening ? 'نشط' : 'متوقف',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Title
                      const Text(
                        'المساعد الصوتي الذكي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      
                      // Close Icon
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. Central AI Orb Assistant with Pulsating Aura
                Center(
                  child: GestureDetector(
                    onTap: _toggleListening,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Breathing Radial Glow
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulsating aura (cyan/blue)
                                Container(
                                  width: 290 * _glowAnimation.value,
                                  height: 290 * _glowAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF6366F1).withOpacity(
                                            0.28 * (1.8 - _glowAnimation.value)),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                // Inner pulsating aura (purple/pink)
                                Container(
                                  width: 210 * _glowAnimation.value,
                                  height: 210 * _glowAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF8B5CF6).withOpacity(
                                            0.38 * (1.8 - _glowAnimation.value)),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        // Lottie Orb Animation
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Lottie.asset(
                            'assets/animations/Orb_Ai_Assistant.json',
                            fit: BoxFit.contain,
                            repeat: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1E1B4B),
                                ),
                                child: const Icon(
                                  Icons.settings_voice_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. Status Text (e.g. "أستمع الآن...", "اضغط للتحدث")
                Text(
                  _statusText,
                  style: TextStyle(
                    color: _isListening
                        ? const Color(0xFFC084FC) // soft purple
                        : Colors.white70,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 30),

                // 5. Sleek dynamic thin caption (No box container, transparent when empty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    height: 100,
                    child: _wordsSpoken.isNotEmpty
                        ? SingleChildScrollView(
                            reverse: true,
                            child: Text(
                              _wordsSpoken,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w300, // slender/thin font weight
                                height: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                const Spacer(),

                // 6. Floating Glassmorphic Discard Button (No Send Button - auto-trigger responds instantly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Center(
                    child: Container(
                      height: 50,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Material(
                          color: const Color(0xFFEF4444).withOpacity(0.08),
                          child: InkWell(
                            onTap: () {
                              _speech.stop();
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.close_rounded, color: Color(0xFFFCA5A5), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontSize: 14,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
