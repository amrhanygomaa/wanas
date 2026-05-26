import 'package:flutter/material.dart';

class AddSkillDialog extends StatefulWidget {
  final Function(String) onAdd;
  const AddSkillDialog({super.key, required this.onAdd});

  @override
  State<AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<AddSkillDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('إضافة مهارة جديدة',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065f46))),
      content: TextField(
        controller: _controller,
        textAlign: TextAlign.right,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'مثال: إسعافات أولية، رسم، غناء...',
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFf0fdf4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFa7f3d0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onAdd(_controller.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
