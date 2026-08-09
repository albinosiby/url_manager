import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/url_model.dart';
import '../services/providers.dart';
import '../services/toast_service.dart';
import '../services/encryption_service.dart';
import '../services/password_generator_service.dart';
import '../widgets/glass_card.dart';
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassCard(
        borderRadius: 32,
        padding: EdgeInsets.all(24.w),
        opacity: 0.18,
        blur: 25,
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
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.neonCyan, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      widget.url == null ? 'New Password Entry' : 'Update Password Entry',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20.sp,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                NeonTextField(
                  controller: _nameController,
                  label: 'Service / Website Name',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                NeonTextField(
                  controller: _urlController,
                  label: 'Website URL (Optional)',
                  icon: Icons.public_outlined,
                ),
                SizedBox(height: 16.h),
                NeonTextField(
                  controller: _userController,
                  label: 'Username / Email',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Password is required' : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.neonCyan,
                      size: 22,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.autorenew_rounded,
                            color: AppTheme.neonCyan,
                            size: 20,
                          ),
                          tooltip: 'Generate Strong Password',
                          onPressed: _generateRandomPassword,
                        ),
                      ],
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.neonCyan, width: 2),
                    ),
                  ),
                ),
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
                SizedBox(height: 16.h),
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
                SizedBox(height: 16.h),
                NeonTextField(
                  controller: _descController,
                  label: 'Notes / Recovery Info (Optional)',
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
                SizedBox(height: 32.h),
                _buildGlowButton(),
                SizedBox(height: 20.h),
              ],
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
                  widget.url == null ? 'Save Password Entry' : 'Apply Changes',
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
