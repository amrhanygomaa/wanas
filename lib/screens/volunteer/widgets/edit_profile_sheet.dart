import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appRiverpod).volunteerProfile;
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);
    _locationController = TextEditingController(text: profile.location);
    _linkedinController = TextEditingController(text: profile.linkedinUrl ?? '');
    _facebookController = TextEditingController(text: profile.facebookUrl ?? '');
    _instagramController = TextEditingController(text: profile.instagramUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appRiverpod).volunteerProfile;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          const Text('تعديل الملف المهني', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF065f46))),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('المعلومات الأساسية'),
                  _buildTextField(_nameController, 'الاسم الكامل', Icons.person_outline),
                  _buildTextField(_locationController, 'الموقع', Icons.location_on_outlined),
                  _buildTextField(_bioController, 'نبذة تعريفية', Icons.description_outlined, maxLines: 3),
                  const SizedBox(height: 24),
                  _buildSectionTitle('الروابط الاجتماعية'),
                  _buildTextField(_linkedinController, 'رابط LinkedIn', Icons.link, prefix: 'in/'),
                  _buildTextField(_facebookController, 'رابط Facebook', Icons.link, prefix: 'fb/'),
                  _buildTextField(_instagramController, 'رابط Instagram', Icons.link, prefix: 'ig/'),
                  const SizedBox(height: 24),
                  _buildSectionTitle('المستندات والملفات'),
                  _buildFileUploadTile(
                    'السيرة الذاتية (CV)', 
                    profile.cvFileName, 
                    () => _simulateUpload('cv')
                  ),
                  _buildFileUploadTile(
                    'خطاب توصية / أعمال سابقة', 
                    profile.recommendationFileName, 
                    () => _simulateUpload('recommendation')
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, String? prefix}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFileUploadTile(String title, String? fileName, VoidCallback onUpload) {
    bool hasFile = fileName != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFf0fdf4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasFile ? const Color(0xFFa7f3d0) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onUpload,
            icon: Icon(hasFile ? Icons.refresh_rounded : Icons.upload_file_rounded, color: const Color(0xFF059669)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(hasFile ? fileName : 'لم يتم الرفع بعد', style: TextStyle(fontSize: 11, color: hasFile ? const Color(0xFF059669) : Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(hasFile ? Icons.check_circle_rounded : Icons.description_outlined, color: hasFile ? const Color(0xFF10b981) : Colors.grey[400]),
        ],
      ),
    );
  }

  void _simulateUpload(String type) {
    final fileName = type == 'cv' ? 'CV_Omar_Ref.pdf' : 'Portfolio_Works.zip';
    ref.read(appRiverpod).uploadVolunteerDocument(type, fileName);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع $type بنجاح!')));
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final updated = ref.read(appRiverpod).volunteerProfile.copyWith(
            name: _nameController.text,
            bio: _bioController.text,
            location: _locationController.text,
            linkedinUrl: _linkedinController.text,
            facebookUrl: _facebookController.text,
            instagramUrl: _instagramController.text,
          );
          ref.read(appRiverpod).updateVolunteerProfile(updated);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
