import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../models/app_models.dart';
import '../../providers/app_riverpod.dart';

class HeartMessagesScreen extends ConsumerStatefulWidget {
  final bool autoRecord;

  const HeartMessagesScreen({super.key, this.autoRecord = false});

  @override
  ConsumerState<HeartMessagesScreen> createState() =>
      _HeartMessagesScreenState();
}

class _HeartMessagesScreenState extends ConsumerState<HeartMessagesScreen> {
  final _titleCtrl = TextEditingController(text: 'رسالة من القلب');
  final _recorder = AudioRecorder();

  String? _selectedMemberId;
  String? _recordedPath;
  bool _isRecording = false;
  bool _isSending = false;
  bool? _micAllowed;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshMicPermission();
      if (widget.autoRecord && mounted && !_isRecording) {
        await _toggleRecording();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _refreshMicPermission() async {
    final allowed = await _recorder.hasPermission();
    if (mounted) setState(() => _micAllowed = allowed);
  }

  FamilyMember? _selectedMember(List<FamilyMember> members) {
    if (_selectedMemberId == null) return null;
    return members
        .where((member) => member.id == _selectedMemberId)
        .firstOrNull;
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _timer?.cancel();
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
      return;
    }

    final allowed = await _recorder.hasPermission();
    setState(() => _micAllowed = allowed);
    if (!allowed) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/heart_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _send(AppRiverpod provider, List<FamilyMember> members) async {
    if (_recordedPath == null || _isSending) return;
    setState(() => _isSending = true);

    final selected = _selectedMember(members);
    final title = _titleCtrl.text.trim().isEmpty
        ? 'رسالة من القلب'
        : _titleCtrl.text.trim();
    final result = await provider.sendVoiceMessageFromResident(
      title,
      audioPath: _recordedPath,
      durationSeconds: _seconds,
      recipientId: selected?.userId,
      familyMemberId: selected?.id,
      recipientName: selected?.name ?? 'كل الأسرة',
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (result?.deliveryStatus != 'failed') {
        _recordedPath = null;
        _seconds = 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result?.deliveryStatus == 'failed'
            ? 'تعذر إرسال الرسالة. ستظهر لك الحالة في القائمة.'
            : 'تم إرسال الرسالة ومتابعة حالتها من القائمة'),
        backgroundColor: result?.deliveryStatus == 'failed'
            ? const Color(0xFFDC2626)
            : const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final members = provider.familyMembers;
    final sentMessages =
        provider.voiceMessages.where((m) => m.senderId == 'resident').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'رسائل من القلب',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          _buildRecorderCard(provider, members),
          const SizedBox(height: 18),
          _buildSentMessages(sentMessages),
        ],
      ),
    );
  }

  Widget _buildRecorderCard(AppRiverpod provider, List<FamilyMember> members) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _buildStatusChip(
                _micAllowed == null
                    ? 'فحص الميكروفون'
                    : _micAllowed!
                        ? 'الميكروفون مسموح'
                        : 'الميكروفون غير مسموح',
                _micAllowed == false
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
              const Spacer(),
              const Text(
                'سجّل رسالة لعائلتك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            enabled: !_isRecording && !_isSending,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'اسم الرسالة',
              hintText: 'مثال: صباح الخير',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecipientSelector(members),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                if (_isRecording || _recordedPath != null)
                  Text(
                    _timerText,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: _isRecording
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF6C63FF),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isSending ? null : _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isRecording
                            ? const [Color(0xFFDC2626), Color(0xFFF97316)]
                            : _recordedPath != null
                                ? const [Color(0xFF059669), Color(0xFF10B981)]
                                : const [Color(0xFF6C63FF), Color(0xFFA78BFA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF6C63FF))
                              .withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop_rounded
                          : _recordedPath != null
                              ? Icons.check_rounded
                              : Icons.mic_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRecording
                      ? 'جاري التسجيل... اضغط للإيقاف'
                      : _recordedPath != null
                          ? 'تم التسجيل. تقدر ترسله الآن'
                          : 'اضغط للبدء في التسجيل',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_recordedPath == null || _isSending)
                  ? null
                  : () => _send(provider, members),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                _isSending ? 'جاري الإرسال...' : 'إرسال الرسالة',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientSelector(List<FamilyMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'إرسال إلى',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            children: [
              _recipientChip('كل الأسرة', null, _selectedMemberId == null),
              ...members.map((member) => _recipientChip(
                    '${member.name} · ${member.relation}',
                    member.id,
                    _selectedMemberId == member.id,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recipientChip(String label, String? id, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: const Color(0xFFEDE9FE),
        backgroundColor: const Color(0xFFF8FAFC),
        checkmarkColor: const Color(0xFF6C63FF),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF6C63FF) : const Color(0xFF64748B),
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _selectedMemberId = id),
      ),
    );
  }

  Widget _buildSentMessages(List<VoiceMessage> messages) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'الرسائل التي أرسلتها',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          if (messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'لسه مفيش رسائل مرسلة',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...messages.map((message) => _sentMessageCard(message)),
        ],
      ),
    );
  }

  Widget _sentMessageCard(VoiceMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _buildStatusChip(
                _deliveryLabel(message.deliveryStatus),
                _deliveryColor(message.deliveryStatus),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: Text(
                  message.title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusChip(
                _moderationLabel(message.moderationStatus),
                _moderationColor(message.moderationStatus),
              ),
              const Spacer(),
              Text(
                'إلى: ${message.recipientName ?? 'كل الأسرة'}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${message.timeDescription} · ${_durationLabel(message.durationSeconds)}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _durationLabel(int? seconds) {
    if (seconds == null || seconds <= 0) return 'مدة غير محددة';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _deliveryLabel(String status) {
    final clean = status.toLowerCase();
    if (clean == 'failed') return 'لم يصل';
    if (clean == 'pending') return 'جاري الإرسال';
    if (clean == 'delivered' || clean == 'sent' || clean == 'confirmed') {
      return 'وصل';
    }
    return 'حالة الوصول: $status';
  }

  Color _deliveryColor(String status) {
    final clean = status.toLowerCase();
    if (clean == 'failed') return const Color(0xFFDC2626);
    if (clean == 'pending') return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  String _moderationLabel(String status) {
    final clean = status.toLowerCase();
    if (clean == 'approved' || clean == 'allowed') return 'مسموح';
    if (clean == 'rejected' || clean == 'blocked') return 'غير مسموح';
    return 'بانتظار السماح';
  }

  Color _moderationColor(String status) {
    final clean = status.toLowerCase();
    if (clean == 'approved' || clean == 'allowed') {
      return const Color(0xFF059669);
    }
    if (clean == 'rejected' || clean == 'blocked') {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF6C63FF);
  }
}
