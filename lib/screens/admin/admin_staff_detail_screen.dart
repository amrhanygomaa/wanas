import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../widgets/taptaba_scaffold.dart';

class AdminStaffDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  final String name;
  final String role;
  final double rate;
  final String status;
  final String time;

  const AdminStaffDetailScreen({
    super.key,
    required this.staffId,
    required this.name,
    required this.role,
    required this.rate,
    required this.status,
    required this.time,
  });

  @override
  ConsumerState<AdminStaffDetailScreen> createState() =>
      _AdminStaffDetailScreenState();
}

class _AdminStaffDetailScreenState
    extends ConsumerState<AdminStaffDetailScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    bool isNurse = widget.role == 'Nurse' || widget.role == 'ممرض';
    bool isOnline = widget.status == 'online';

    return TaptabaScaffold(
      title: 'ونس',
      titleColor: const Color(0xFF0F172A),
      overrideRole: 'مدير',
      body: DefaultTabController(
        length: 3,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildProfileHeader(context, isNurse, isOnline),
              const TabBar(
                labelColor: Color(0xFF0ea5e9),
                unselectedLabelColor: Color(0xFF64748b),
                indicatorColor: Color(0xFF0ea5e9),
                tabs: [
                  Tab(text: 'الأداء والإنجاز'),
                  Tab(text: 'البيانات الشخصية'),
                  Tab(text: 'المستندات'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Performance
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoCard('الأداء والإنجاز', [
                          const Text('معدل إنجاز المهام اليومية',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748b))),
                          const SizedBox(height: 8),
                          _buildCompletionBar(widget.rate),
                        ]),
                      ],
                    ),
                    // Tab 2: Personal Info
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoCard('البيانات الشخصية والمهنية', [
                          _infoRow(
                              'الرقم الوظيفي',
                              'EMP-${widget.name.hashCode.toString().substring(0, 4)}',
                              Icons.badge_outlined),
                          _infoRow('الرقم القومي', '29501012345678',
                              Icons.credit_card_outlined),
                          _infoRow(
                              'البريد الإلكتروني',
                              '${widget.name.replaceAll(' ', '.').toLowerCase()}@tbtba.com',
                              Icons.email_outlined),
                          _infoRow(
                              'المؤهل',
                              isNurse
                                  ? 'بكالوريوس تمريض'
                                  : 'ليسانس آداب قسم اجتماع',
                              Icons.school_outlined),
                          if (isNurse) ...[
                            _infoRow('القسم', 'العناية المركزة',
                                Icons.local_hospital_outlined),
                            _infoRow('الوردية', 'صباحية (8 ص - 4 م)',
                                Icons.schedule_rounded),
                          ] else ...[
                            _infoRow('القسم', 'الدعم النفسي والاجتماعي',
                                Icons.psychology_outlined),
                            _infoRow('الحالات المتابعة', '12 حالة',
                                Icons.people_outline),
                          ],
                        ]),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(context),
                          icon: const Icon(Icons.delete_forever_rounded,
                              color: Colors.redAccent, size: 20),
                          label: const Text('حذف ملف الموظف نهائياً',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                    // Tab 3: Documents
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoCard('المستندات ومسوغات التعيين', [
                          _infoRow('الفيش الجنائي', 'تم الاستلام (ساري)',
                              Icons.assignment_turned_in_outlined,
                              valColor: Colors.green),
                          _infoRow('شهادة التخرج', 'تم الاستلام',
                              Icons.card_membership_outlined),
                          _infoRow(
                              'ترخيص مزاولة المهنة',
                              isNurse ? 'تم الاستلام (ساري)' : 'غير مطلوب',
                              isNurse
                                  ? Icons.verified_user_outlined
                                  : Icons.block_flipped,
                              valColor: isNurse ? Colors.green : Colors.grey),
                          _infoRow('تاريخ التعيين', '01/01/2025',
                              Icons.calendar_today_outlined),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, bool isNurse, bool isOnline) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('ملف الموظف',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(
                    _isEditMode
                        ? Icons.check_circle_rounded
                        : Icons.edit_note_rounded,
                    color: _isEditMode ? Colors.greenAccent : Colors.white,
                    size: 28),
                onPressed: () {
                  setState(() => _isEditMode = !_isEditMode);
                  if (!_isEditMode) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم حفظ التعديلات بنجاح')));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Hero(
                  tag: widget.staffId,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final provider = ref.watch(appRiverpod);
                      final staffList = provider.staffPerformanceList;
                      final staff = staffList.firstWhere(
                        (s) => s.id == widget.staffId,
                        orElse: () => StaffPerformance(
                          id: widget.staffId,
                          name: widget.name,
                          role: widget.role,
                          completionRate: widget.rate,
                          lastActive: widget.time,
                          status: widget.status,
                        ),
                      );

                      final String? imageUrl = staff.imageUrl;

                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white12,
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? FileImage(File(imageUrl))
                                : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 60)
                            : null,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ref.read(appRiverpod).pickAndSetStaffImage(widget.staffId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0ea5e9),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF1e293b), width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isNurse ? 'طاقم التمريض' : 'أخصائي اجتماعي',
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'نشط' : 'غير نشط',
                style: TextStyle(
                    fontSize: 14,
                    color: isOnline
                        ? Colors.greenAccent
                        : Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: InkWell(
        onTap: _isEditMode ? () {} : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369a1))),
                  if (_isEditMode)
                    const Icon(Icons.edit_rounded,
                        size: 18, color: Colors.blueAccent),
                ],
              ),
              const Divider(
                  height: 25, color: Color(0xFFf1f5f9), thickness: 1.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon,
      {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF0ea5e9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94a3b8))),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: valColor ?? const Color(0xFF1e293b)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBar(double rate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(rate * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0ea5e9))),
            Text(rate >= 0.8 ? 'ممتاز' : 'جيد',
                style: TextStyle(
                    fontSize: 12,
                    color: rate >= 0.8 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: const Color(0xFFf1f5f9),
            valueColor: AlwaysStoppedAnimation<Color>(rate >= 0.8
                ? const Color(0xFF10b981)
                : const Color(0xFF0ea5e9)),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد الحذف النهائي ⚠️',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف ملف الموظف "${widget.name}" بالكامل؟ لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف ملف الموظف بنجاح')));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('نعم، احذف الملف'),
          ),
        ],
      ),
    );
  }
}
