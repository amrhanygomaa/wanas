import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/app_riverpod.dart';
import '../chat/family_resident_chat_screen.dart';

class ElderlyContactsScreen extends ConsumerWidget {
  const ElderlyContactsScreen({super.key});

  static const _accent = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    final members = provider.familyMembers;
    final residentId = provider.backendResidentId;

    final chatMembers = members.where((m) => m.userId != null).toList();
    final otherMembers = members.where((m) => m.userId == null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          if (members.isEmpty)
            SliverFillRemaining(child: _buildEmpty(context))
          else ...[
            if (chatMembers.isNotEmpty) ...[
              _buildSectionHeader('تواصل عبر التطبيق', Icons.chat_rounded),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ContactCard(
                      member: chatMembers[i],
                      residentId: residentId,
                      index: i,
                    ),
                    childCount: chatMembers.length,
                  ),
                ),
              ),
            ],
            if (otherMembers.isNotEmpty) ...[
              _buildSectionHeader('التواصل بالهاتف فقط', Icons.phone_rounded,
                  color: const Color(0xFF6B7280)),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _PhoneOnlyCard(
                      member: otherMembers[i],
                      provider: provider,
                      index: i,
                    ),
                    childCount: otherMembers.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تواصل مع عائلتك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ابعت رسالة أو صورة لأي وقت',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'العائلة',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        titlePadding: const EdgeInsets.only(right: 56, bottom: 16),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, IconData icon,
      {Color color = _accent}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.people_outline_rounded, size: 48, color: _accent),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا يوجد أفراد عائلة مضافون',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1a1a1a),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'تواصل مع المشرفين لإضافة أفراد عائلتك',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact card (has app → can chat) ──────────────────────────────────────

class _ContactCard extends ConsumerWidget {
  final FamilyMember member;
  final String? residentId;
  final int index;

  const _ContactCard({
    required this.member,
    required this.residentId,
    required this.index,
  });

  static const _gradients = [
    [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
    [Color(0xFFEA580C), Color(0xFFDC2626)],
    [Color(0xFF059669), Color(0xFF0284C7)],
    [Color(0xFFDB2777), Color(0xFF9333EA)],
    [Color(0xFF0891B2), Color(0xFF2563EB)],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradPair = _gradients[index % _gradients.length];
    final initials = _initials(member.name);
    final isOnline = member.isAvailable;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FamilyResidentChatScreen(
            otherUserId: member.userId!,
            otherUserName: member.name,
            otherUserRole: member.relation,
            residentId: residentId,
            accentColor: gradPair[0],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradPair[0].withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradPair,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1a1a1a),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradPair[0].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.relation,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: gradPair[0],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF9CA3AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'متصل الآن' : 'غير متصل',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOnline
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action: Chat button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradPair,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradPair[0].withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.15, end: 0),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isNotEmpty ? name[0] : '?';
  }
}

// ── Phone-only card (no app access) ────────────────────────────────────────

class _PhoneOnlyCard extends StatelessWidget {
  final FamilyMember member;
  final AppRiverpod provider;
  final int index;

  const _PhoneOnlyCard({
    required this.member,
    required this.provider,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = member.phoneNumber.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.relation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (hasPhone)
              GestureDetector(
                onTap: () => provider.callPhoneNumber(member.phoneNumber),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_rounded,
                      color: Color(0xFF16A34A), size: 20),
                ),
              )
            else
              const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 250.ms);
  }
}
