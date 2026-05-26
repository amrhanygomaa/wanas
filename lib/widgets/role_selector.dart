import 'package:flutter/material.dart';
import '../constants.dart';
import '../svg_icons.dart';

class RoleSelector extends StatefulWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;
  static const List<String> defaultRoles = [
    'مسن',
    'ممرض',
    'أسرة',
    'متطوع',
    'أخصائي اجتماعي',
    'إدارة'
  ];

  final List<String> roles;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.roles = defaultRoles,
  });

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.roles.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );
    _animations = _controllers
        .map(
          (controller) => Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
        )
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + (i * 80)), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'أنا...',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.roles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemBuilder: (context, index) {
            final role = widget.roles[index];
            Widget icon;
            switch (role) {
              case 'مسن':
                icon = AppIcons.user(size: 14);
                break;
              case 'ممرض':
                icon = AppIcons.nurse(size: 14);
                break;
              case 'أسرة':
                icon = AppIcons.family(size: 14);
                break;
              case 'متطوع':
                icon = AppIcons.volunteer(size: 14);
                break;
              case 'أخصائي اجتماعي':
                icon = AppIcons.user(size: 14);
                break;
              case 'إدارة':
                icon = AppIcons.user(size: 14);
                break;
              default:
                icon = AppIcons.user(size: 14);
            }
            return _buildRoleCard(role, index, icon);
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role, int index, Widget icon) {
    final isSelected = widget.selectedRole == role;
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _animations[index].value,
          child: GestureDetector(
            onTap: () => widget.onRoleChanged(role),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.bgInput,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.borderInput,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.bgPurpleLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isSelected ? _buildWhiteIcon(role) : icon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhiteIcon(String role) {
    switch (role) {
      case 'مسن':
        return AppIcons.user(size: 14, color: Colors.white.withValues(alpha: 0.9));
      case 'ممرض':
        return AppIcons.nurse(size: 14, color: Colors.white.withValues(alpha: 0.9));
      case 'أسرة':
        return AppIcons.family(size: 14, color: Colors.white.withValues(alpha: 0.9));
      case 'متطوع':
        return AppIcons.volunteer(
          size: 14,
          color: Colors.white.withValues(alpha: 0.9),
        );
      case 'أخصائي اجتماعي':
        return AppIcons.user(size: 14, color: Colors.white.withValues(alpha: 0.9));
      case 'إدارة':
        return AppIcons.user(size: 14, color: Colors.white.withValues(alpha: 0.9));
      default:
        return AppIcons.user(size: 14, color: Colors.white.withValues(alpha: 0.9));
    }
  }
}
