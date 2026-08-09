import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/url_model.dart';
import '../services/providers.dart';
import '../services/toast_service.dart';
import '../services/encryption_service.dart';
import '../services/password_generator_service.dart';
import '../widgets/neon_text_field.dart';
import '../core/app_theme.dart';

class PasswordFormScreen extends ConsumerStatefulWidget {
  final UrlModel? url;

  const PasswordFormScreen({super.key, this.url});

  @override
  ConsumerState<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends ConsumerState<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _userController;
  late TextEditingController _passController;
  late TextEditingController _descController;
  late String _selectedCategory;
  bool _obscurePassword = true;
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
    _userController = TextEditingController(text: widget.url?.username ?? '');
    final rawPass = widget.url?.password;
    final decryptedPass = (rawPass != null && rawPass.isNotEmpty)
        ? EncryptionService.decrypt(rawPass)
        : '';
    _passController = TextEditingController(text: decryptedPass);
    _descController = TextEditingController(text: widget.url?.description ?? '');
    _selectedCategory = widget.url?.category ?? 'General';

    _passController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _generateRandomPassword() {
    final newPass = PasswordGeneratorService.generatePassword(length: 16);
    setState(() {
      _passController.text = newPass;
      _obscurePassword = false;
    });
    HapticFeedback.lightImpact();
    ToastService.show(context, 'Strong Password Generated');
  }

  @override
  Widget build(BuildContext context) {
    final strength = PasswordGeneratorService.calculateStrength(_passController.text);

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
              color: AppTheme.titaniumSlate.withOpacity(0.4),
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
                                    color: AppTheme.titaniumSlate.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.shield_rounded,
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
                                      widget.url == null ? 'New Password Entry' : 'Update Password',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'AES-256 Client-Side Encrypted',
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

                    // Service Name
                    NeonTextField(
                      controller: _nameController,
                      label: 'Service / Website Name (e.g. GitHub)',
                      icon: Icons.label_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    SizedBox(height: 16.h),

                    // Website URL
                    NeonTextField(
                      controller: _urlController,
                      label: 'Website URL (Optional)',
                      icon: Icons.public_rounded,
                    ),
                    SizedBox(height: 16.h),

                    // Username Field
                    NeonTextField(
                      controller: _userController,
                      label: 'Username / Email',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                    ),
                    SizedBox(height: 16.h),

                    // Password Field with Generator & Strength Meter
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Password is required' : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.titaniumSilver,
                          size: 20,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.autorenew_rounded,
                                color: AppTheme.titaniumSilver,
                                size: 20,
                              ),
                              tooltip: 'Generate Strong Password',
                              onPressed: _generateRandomPassword,
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.titaniumSilver, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                        ),
                      ),
                    ),

                    // Strength Progress Meter
                    if (_passController.text.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: strength.score,
                                color: strength.color,
                                backgroundColor: Colors.white10,
                                minHeight: 4.h,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            strength.label,
                            style: TextStyle(
                              color: strength.color,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 20.h),

                    // Category Selector
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

                    // Recovery Notes
                    NeonTextField(
                      controller: _descController,
                      label: 'Notes / Recovery Info (Optional)',
                      icon: Icons.notes_rounded,
                      maxLines: 2,
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
      onTap: _isSaving ? null : _savePassword,
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
                  widget.url == null ? 'Save Encrypted Password' : 'Apply Changes',
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

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final rawPassword = _passController.text.trim();
      final encryptedPass = EncryptionService.encrypt(rawPassword);
      final urlVal = _urlController.text.trim();

      final newUrl = UrlModel(
        id: widget.url?.id,
        name: _nameController.text.trim(),
        url: urlVal.isEmpty ? 'https://' : (urlVal.startsWith('http') ? urlVal : 'https://$urlVal'),
        description: _descController.text.trim(),
        createdAt: widget.url?.createdAt ?? DateTime.now(),
        isFavorite: widget.url?.isFavorite ?? false,
        category: _selectedCategory,
        username: _userController.text.trim(),
        password: encryptedPass,
      );

      if (widget.url == null) {
        await firestore.addUrl(newUrl);
        if (mounted) ToastService.show(context, 'Password Saved');
      } else {
        await firestore.updateUrl(newUrl);
        if (mounted) ToastService.show(context, 'Password Updated');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ToastService.show(context, 'Error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
