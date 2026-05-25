import 'dart:async';

import 'package:flutter/material.dart';
import '../services/residents_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

// بانر يعرض المقيمين المباشرين من قاعدة بيانات AWS RDS
// يُستخدم في شاشات الممرض/الأخصائي/الإدارة لإثبات الـ live integration.
class LiveCloudResidentsBanner extends StatefulWidget {
  const LiveCloudResidentsBanner({super.key});

  @override
  State<LiveCloudResidentsBanner> createState() =>
      _LiveCloudResidentsBannerState();
}

class _LiveCloudResidentsBannerState extends State<LiveCloudResidentsBanner> {
  Future<List<BackendResident>>? _future;
  bool _isAuthenticated = false;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await ApiClient.instance.getToken();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = token != null;
      if (_isAuthenticated) {
        _future = ResidentsService.instance.getAll();
      }
    });
    if (_isAuthenticated) _startRealtime();
  }

  void _startRealtime() {
    _realtimeSub ??=
        RealtimeService.instance.liveEventsFor({'residents'}).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  void _refresh() => setState(() {
        _future = ResidentsService.instance.getAll();
      });

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _shell(
        child: const _StatusRow(
          icon: Icons.cloud_off_rounded,
          color: Color(0xFF94A3B8),
          title: 'غير متصل بالسحابة',
          subtitle: 'سجّل دخولك بحساب Cognito لرؤية بيانات RDS الحية',
        ),
      );
    }
    return _shell(
      child: FutureBuilder<List<BackendResident>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _StatusRow(
              icon: Icons.cloud_sync_rounded,
              color: Color(0xFFFF9900),
              title: 'جاري التحميل من AWS RDS...',
              subtitle: 'PostgreSQL في us-east-1',
              isLoading: true,
            );
          }
          if (snap.hasError) {
            return _StatusRow(
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFEF4444),
              title: 'فشل الاتصال بالسحابة',
              subtitle: '${snap.error}',
              trailing: _refreshBtn(),
            );
          }
          final residents = snap.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text('Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Color(0xFF065F46),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AWS RDS · PostgreSQL · ${residents.length} مقيم',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _refreshBtn(),
                ],
              ),
              if (residents.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children:
                        residents.take(5).map((r) => _residentChip(r)).toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _refreshBtn() {
    return InkWell(
      onTap: _refresh,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF4338CA)),
            SizedBox(width: 4),
            Text('تحديث',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Color(0xFF4338CA),
                )),
          ],
        ),
      ),
    );
  }

  Widget _residentChip(BackendResident r) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            r.fullName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: Color(0xFF1E293B),
            ),
          ),
          if (r.roomNumber != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'غرفة ${r.roomNumber}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: Color(0xFF4338CA),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFFFF7ED).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF9900).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9900).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;
  final Widget? trailing;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          )
        else
          Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontFamily: 'Cairo',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
