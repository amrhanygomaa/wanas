import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية

class BottomNavBar extends StatelessWidget { // فئة شريط التنقل السفلي المخصص للمسن
  final int currentIndex; // الفهرس الحالي المختار
  final Function(int) onTap; // دالة المعالجة عند الضغط على أيقونة

  const BottomNavBar({ // مشيد الفئة
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) { // دالة بناء الواجهة
    final isDark = Theme.of(context).brightness == Brightness.dark; // التحقق من نمط الألوان (ليلي/نهاري)
    final items = [ // قائمة عناصر شريط التنقل
      const BottomNavItem(icon: Icons.home_rounded, label: 'الرئيسية', index: 0), // الرئيسية
      const BottomNavItem(icon: Icons.medication_rounded, label: 'دواء', index: 1), // تنبيهات الأدوية
      const BottomNavItem(icon: Icons.circle, label: '', index: -1), // مساحة فارغة للكرة
      const BottomNavItem(icon: Icons.people_rounded, label: 'أسرة', index: 2), // التواصل مع الأسرة
      const BottomNavItem(icon: Icons.photo_rounded, label: 'ذكريات', index: 3), // ألبوم الصور
    ];

    return Container( // وعاء شريط التنقل
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // لون الخلفية حسب النمط
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFede9fe), width: 1)), // إطار علوي خفيف
      ),
      child: Row( // ترتيب العناصر أفقياً
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _buildNavItem(context, item)).toList(), // تحويل القائمة لمكونات واجهة
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, BottomNavItem item) { // دالة بناء عنصر تنقل فردي
    if (item.index == -1) return const SizedBox(width: 60); // المساحة الفارغة للكرة

    final isDark = Theme.of(context).brightness == Brightness.dark; // النمط الحالي
    final isActive = currentIndex == item.index; // هل هذا العنصر هو النشط؟
    final color = isActive ? const Color(0xFF6C63FF) : (isDark ? Colors.white38 : const Color(0xFF9ca3af)); // اللون بناءً على الحالة

    return GestureDetector( // كاشف للمسات
      onTap: () => onTap(item.index), // تنفيذ دالة التنقل عند الضغط
      child: Column( // ترتيب أيقونة + نص
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: color, size: 24), // أيقونة العنصر
          const SizedBox(height: 4),
          Text(item.label, // نص العنصر (عربي)
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}

class BottomNavItem { // فئة نموذج بيانات عنصر التنقل
  final IconData icon; // أيقونة العنصر
  final String label; // نص العنصر
  final int index; // فهرس العنصر

  const BottomNavItem({ // مشيد نموذج البيانات
    required this.icon,
    required this.label,
    required this.index,
  });
}
