import 'package:flutter/material.dart';
import '../../services/residents_service.dart';
import '../../services/api_client.dart';
import '../../widgets/sheets/create_resident_sheet.dart';

// شاشة مقيمين 100% مربوطة بـ AWS RDS — لا mock data إطلاقاً
class RealResidentsScreen extends StatefulWidget {
  const RealResidentsScreen({super.key});

  @override
  State<RealResidentsScreen> createState() => _RealResidentsScreenState();
}

class _RealResidentsScreenState extends State<RealResidentsScreen> {
  Future<List<BackendResident>>? _future;
  String _search = '';
  String _statusFilter = 'all';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ApiClient.instance.getToken();
    setState(() {
      _isAuthenticated = token != null;
      if (_isAuthenticated) _refresh();
    });
  }

  void _refresh() => setState(() {
        _future = ResidentsService.instance.getAll(
          status: _statusFilter == 'all' ? null : _statusFilter,
        );
      });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'المقيمون (AWS RDS)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث من السحابة',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isAuthenticated
              ? () => CreateResidentSheet.show(context, onCreated: _refresh)
              : null,
          backgroundColor: const Color(0xFFFF9900),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text(
            'إضافة مقيم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: !_isAuthenticated
            ? _unauthState()
            : Column(
                children: [
                  _buildHeader(),
                  _buildSearchFilter(),
                  Expanded(child: _buildList()),
                ],
              ),
      ),
    );
  }

  Widget _unauthState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 60, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'سجّل دخولك بحساب Cognito أولاً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Live · AWS RDS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                fontFamily: 'Cairo',
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'PostgreSQL · facility-scoped',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontFamily: 'Cairo',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _search = v),
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو رقم الغرفة...',
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _filterChip('الكل', 'all'),
                _filterChip('نشط', 'active'),
                _filterChip('خرج', 'discharged'),
                _filterChip('متوفى', 'deceased'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9900) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFFF9900) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<BackendResident>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _errorState(snap.error.toString());
        }
        final all = snap.data ?? [];
        final filtered = _search.isEmpty
            ? all
            : all
                .where((r) =>
                    r.fullName.toLowerCase().contains(_search.toLowerCase()) ||
                    (r.roomNumber?.contains(_search) ?? false))
                .toList();
        if (filtered.isEmpty) {
          return _emptyState();
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _residentCard(filtered[i]),
          ),
        );
      },
    );
  }

  Widget _residentCard(BackendResident r) {
    final statusColor = switch (r.status) {
      'active' => const Color(0xFF10B981),
      'discharged' => const Color(0xFFF59E0B),
      'deceased' => const Color(0xFF64748B),
      _ => const Color(0xFF94A3B8),
    };
    final arabicStatus = switch (r.status) {
      'active' => 'نشط',
      'discharged' => 'خرج',
      'deceased' => 'متوفى',
      _ => r.status,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Text(
              r.firstName.isNotEmpty ? r.firstName[0] : '?',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.fullName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (r.roomNumber != null) ...[
                      const Icon(Icons.meeting_room_rounded,
                          size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'غرفة ${r.roomNumber}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (r.age != null) ...[
                      const Icon(Icons.cake_rounded,
                          size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${r.age} سنة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              arabicStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 60, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'فشل تحميل المقيمين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 60, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'لا يوجد مقيمين',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'اضغط + لإضافة أول مقيم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
