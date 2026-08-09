import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/url_model.dart';
import '../services/providers.dart';
import '../services/toast_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/neon_text_field.dart';
import '../core/app_theme.dart';

class UrlFormScreen extends ConsumerStatefulWidget {
  final UrlModel? url;

  const UrlFormScreen({super.key, this.url});

  @override
  ConsumerState<UrlFormScreen> createState() => _UrlFormScreenState();
}

class _UrlFormScreenState extends ConsumerState<UrlFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _descController;
  late String _selectedCategory;
  bool _isSaving = false;

  static const List<String> _categories = [
    'General',
    'Work',
    'Dev',
    'Personal',
    'Finance',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.url?.name ?? '');
    _urlController = TextEditingController(text: widget.url?.url ?? '');
    _descController = TextEditingController(
      text: widget.url?.description ?? '',
    );
    _selectedCategory = widget.url?.category ?? 'General';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassCard(
        borderRadius: 32,
        padding: EdgeInsets.all(24.w),
        opacity: 0.15,
        blur: 20,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  widget.url == null ? 'New Bookmark Connection' : 'Update Connection',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22.sp,
                    color: AppTheme.neonCyan,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                NeonTextField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: 20.h),
                NeonTextField(
                  controller: _urlController,
                  label: 'URL',
                  icon: Icons.public_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final trimmed = v.trim();
                    if (!trimmed.startsWith('http')) return 'Invalid URL';
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = cat == _selectedCategory;
                      final catColor = AppTheme.getCategoryColor(cat);
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: catColor.withOpacity(0.2),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: BorderSide(
                            color: isSelected ? catColor : Colors.white10,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? catColor : Colors.white60,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.sp,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20.h),
                NeonTextField(
                  controller: _descController,
                  label: 'Notes (Optional)',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                SizedBox(height: 40.h),
                _buildGlowButton(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveUrl,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FACFE), Color(0xFF00F2FF)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  widget.url == null ? 'Save Connection' : 'Apply Changes',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final newUrl = UrlModel(
        id: widget.url?.id,
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
        description: _descController.text.trim(),
        createdAt: widget.url?.createdAt ?? DateTime.now(),
        isFavorite: widget.url?.isFavorite ?? false,
        category: _selectedCategory,
        username: widget.url?.username,
        password: widget.url?.password,
      );

      if (widget.url == null) {
        await firestore.addUrl(newUrl);
        if (mounted) ToastService.show(context, 'Success');
      } else {
        await firestore.updateUrl(newUrl);
        if (mounted) ToastService.show(context, 'Updated');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ToastService.show(context, 'Error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
