import 'package:flutter/material.dart';
import '../constants.dart';
import '../svg_icons.dart';

class CustomInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isPassword;
  final bool isPhone;
  final Widget? icon;
  final bool showEye;
  final VoidCallback? onEyeTap;

  const CustomInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.isPhone = false,
    this.icon,
    this.showEye = false,
    this.onEyeTap,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isPassword) return;
    _obscureText = true;
  }

  void _toggleObscure() {
    setState(() => _obscureText = !_obscureText);
    widget.onEyeTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textPurple,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.borderInput, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                SizedBox(width: 14, height: 14, child: widget.icon),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: widget.isPassword && _obscureText,
                  keyboardType: widget.isPhone
                      ? TextInputType.phone
                      : (widget.isPassword
                          ? TextInputType.visiblePassword
                          : TextInputType.text),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1f2937),
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.isPassword && widget.showEye) ...[
                GestureDetector(
                  onTap: _toggleObscure,
                  child: _obscureText
                      ? AppIcons.eye(size: 16)
                      : AppIcons.eye(
                          size: 16,
                          color: Colors
                              .grey), // Using eye with grey for slash effect
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
