import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/url_model.dart';
import '../services/providers.dart';
import '../services/toast_service.dart';
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: AppTheme.surface,
            border: Border.all(
              color: AppTheme.titaniumSilver.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(22.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metallic Drag Handle Bar
                    Center(
                      child: Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppTheme.titaniumSilver.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Top Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppTheme.titaniumSilver.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  widget.url == null ? Icons.add_link_rounded : Icons.edit_rounded,
                                  color: AppTheme.titaniumSilver,
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.url == null ? 'New Connection' : 'Update Connection',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Web Link & Vault Manager',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppTheme.titaniumSlate,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Inputs Section
                    NeonTextField(
                      controller: _nameController,
                      label: 'Bookmark Name',
                      icon: Icons.label_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    SizedBox(height: 16.h),
                    NeonTextField(
                      controller: _urlController,
                      label: 'Website URL (e.g. https://github.com)',
                      icon: Icons.public_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'URL is required';
                        final trimmed = v.trim();
                        if (!trimmed.startsWith('http')) return 'URL must start with http:// or https://';
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Category Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category Tag',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedCategory,
                          style: TextStyle(
                            color: AppTheme.getCategoryColor(_selectedCategory),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = cat == _selectedCategory;
                          final catColor = AppTheme.getCategoryColor(cat);
                          final catIcon = AppTheme.getCategoryIcon(cat);

                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: ChoiceChip(
                              avatar: Icon(
                                catIcon,
                                size: 14.sp,
                                color: isSelected ? catColor : Colors.white54,
                              ),
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: catColor.withOpacity(0.2),
                              backgroundColor: Colors.white.withOpacity(0.04),
                              side: BorderSide(
                                color: isSelected ? catColor : Colors.white10,
                                width: isSelected ? 1.4 : 1,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? catColor : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12.sp,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategory = cat);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Notes Field
                    NeonTextField(
                      controller: _descController,
                      label: 'Description / Notes (Optional)',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    SizedBox(height: 30.h),

                    // Save Action Button
                    _buildGlowButton(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
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
        height: 52.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppTheme.titaniumSilver.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
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
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
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
        if (mounted) ToastService.show(context, 'Connection Saved');
      } else {
        await firestore.updateUrl(newUrl);
        if (mounted) ToastService.show(context, 'Connection Updated');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ToastService.show(context, 'Error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
