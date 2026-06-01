import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

class SentReportsHistoryScreen extends ConsumerStatefulWidget {
  const SentReportsHistoryScreen({super.key});

  @override
  ConsumerState<SentReportsHistoryScreen> createState() =>
      _SentReportsHistoryScreenState();
}

class _SentReportsHistoryScreenState
    extends ConsumerState<SentReportsHistoryScreen> {
  String _selectedFilter = 'الكل'; // Filter: All, By Date, By Nurse
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.watch(appRiverpod);

    // Filter sent reports based on selected filter
    final filteredReports = _filterReports(provider.sentReports);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        title: const Text(
          'سجل الإرسال الكامل',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'الكل'),
                  const SizedBox(width: 8),
                  _buildFilterChip('حسب التاريخ', 'التاريخ'),
                  const SizedBox(width: 8),
                  _buildFilterChip('حسب الحالة', 'الحالة'),
                ],
              ),
            ),
          ),

          // Date Picker (if selected)
          if (_selectedFilter == 'التاريخ')
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'اختر التاريخ'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color:
                              isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),
            ),

          // Reports List
          Expanded(
            child: filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 50,
                          color: isDark ? Colors.white24 : Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد تقارير مرسلة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filteredReports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(
                                0.0, 20.0 * (1.0 - value).clamp(-1.0, 1.0)),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: _buildSentReportCard(report),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          if (value != 'التاريخ') {
            _selectedDate = null;
          }
        });
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      selectedColor: const Color(0xFF10B981),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF10B981)
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : const Color(0xFFE2E8F0)),
      ),
    );
  }

  List<SentReport> _filterReports(List<SentReport> reports) {
    switch (_selectedFilter) {
      case 'التاريخ':
        if (_selectedDate == null) return reports;
        return reports.where((report) {
          try {
            final reportDate = DateTime.parse(report.date);
            return reportDate.year == _selectedDate!.year &&
                reportDate.month == _selectedDate!.month &&
                reportDate.day == _selectedDate!.day;
          } catch (e) {
            return false;
          }
        }).toList();
      case 'الحالة':
        return reports.where((report) => report.status == 'تم').toList();
      default:
        return reports;
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildSentReportCard(SentReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine category colors and icons
    Color categoryColor = const Color(0xFF10B981); // Emerald (Daily)
    IconData cardIcon = Icons.assignment_turned_in_rounded;
    IconData metaIcon = Icons.info_outline_rounded;

    if (report.title.contains('حرج') || report.icon == '🚨') {
      categoryColor = const Color(0xFFEF4444); // Red (Critical Alert)
      cardIcon = Icons.emergency_rounded;
      metaIcon = Icons.bolt_rounded;
    } else if (report.title.contains('أسبوعي') || report.icon == '📊') {
      categoryColor = const Color(0xFF8B5CF6); // Purple (Weekly)
      cardIcon = Icons.analytics_rounded;
      metaIcon = Icons.calendar_month_rounded;
    } else if (report.status == 'مجدول') {
      categoryColor = const Color(0xFFF59E0B); // Amber (Scheduled)
      cardIcon = Icons.calendar_today_rounded;
      metaIcon = Icons.schedule_rounded;
    }

    // Dynamic meta icon override
    if (report.meta.contains('تلقائياً')) {
      metaIcon = Icons.autorenew_rounded;
    } else if (report.meta.contains('يدوياً')) {
      metaIcon = Icons.send_rounded;
    } else if (report.meta.contains('مجدول')) {
      metaIcon = Icons.schedule_rounded;
    }

    // Parse title for beautiful visual hierarchy
    String mainTitle = report.title;
    String subtitle = '';
    if (report.title.contains('—')) {
      final parts = report.title.split('—');
      mainTitle = parts[0].trim();
      subtitle = parts[1].trim();
    } else if (report.title.contains(' - ')) {
      final parts = report.title.split(' - ');
      mainTitle = parts[0].trim();
      subtitle = parts[1].trim();
    }

    // Status Badge colors
    Color statusBg = isDark
        ? const Color(0xFF065F46).withValues(alpha: 0.15)
        : const Color(0xFFE6FDF5);
    Color statusFg = const Color(0xFF059669);
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (report.status == 'مجدول') {
      statusBg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.15)
          : const Color(0xFFFFFBEB);
      statusFg = const Color(0xFFD97706);
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent line indicator on the right side (RTL friendly)
              Container(
                width: 5,
                color: categoryColor,
              ),

              // Card content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Styled Glowing Icon Container
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(
                              alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor.withValues(
                                alpha: isDark ? 0.25 : 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            cardIcon,
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Report info (Title & Meta)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  mainTitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '•  $subtitle',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  metaIcon,
                                  size: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    report.meta,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Dynamic Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusFg.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 11,
                              color: statusFg,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              report.status,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
