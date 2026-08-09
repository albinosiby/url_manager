import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/url_model.dart';
import '../services/providers.dart';
import '../services/toast_service.dart';
import '../services/biometric_service.dart';
import '../services/encryption_service.dart';
import '../services/password_generator_service.dart';
import '../widgets/glass_card.dart';
import '../core/app_theme.dart';
import 'url_form_screen.dart';
import 'password_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0 = URL Vault, 1 = Password Vault
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isGridView = false;
  bool _isVaultLocked = false;
  final BiometricService _biometricService = BiometricService();

  static const List<String> _categories = [
    'All',
    'Favorites',
    'General',
    'Work',
    'Dev',
    'Personal',
    'Finance',
    'Social',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleVaultLock() async {
    if (_isVaultLocked) {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        setState(() => _isVaultLocked = false);
        if (mounted) ToastService.show(context, 'Vault Unlocked');
      } else {
        if (mounted) ToastService.show(context, 'Authentication Failed', isError: true);
      }
    } else {
      setState(() => _isVaultLocked = true);
      ToastService.show(context, 'Vault Locked');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVaultLocked) {
      return _buildLockedVaultScreen();
    }

    final urlsAsync = ref.watch(urlsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient Cyber Orbs
          Positioned(
            top: -80.h,
            left: -60.w,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withOpacity(0.08),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 4.seconds,
                ),
          ),
          Positioned(
            bottom: 100.h,
            right: -80.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonPurple.withOpacity(0.08),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 5.seconds,
                ),
          ),
          Column(
            children: [
              _buildTopHeader(urlsAsync.value?.length ?? 0),
              _buildSectionTabBar(),
              if (_selectedTab == 0) _buildCategoryChips(),
              SizedBox(height: 6.h),
              Expanded(
                child: urlsAsync.when(
                  data: (urls) {
                    if (_selectedTab == 1) {
                      // Password Vault Tab
                      final passUrls = urls.where((u) => u.hasCredentials).where((u) {
                        return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            u.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (u.username != null &&
                                u.username!.toLowerCase().contains(_searchQuery.toLowerCase()));
                      }).toList();

                      if (passUrls.isEmpty) {
                        return _buildEmptyPasswordState(urls.isNotEmpty);
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        itemCount: passUrls.length,
                        itemBuilder: (context, index) {
                          final url = passUrls[index];
                          return _buildDismissiblePasswordCard(url, index);
                        },
                      );
                    }

                    // URL Vault Tab (Bookmarks)
                    final filteredUrls = urls.where((u) {
                      final matchesSearch = u.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                          u.url.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                          u.description.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              );

                      if (!matchesSearch) return false;

                      if (_selectedCategory == 'Favorites') {
                        return u.isFavorite;
                      } else if (_selectedCategory != 'All') {
                        return u.category == _selectedCategory;
                      }
                      return true;
                    }).toList();

                    if (filteredUrls.isEmpty) {
                      return _buildEmptyState(urls.isNotEmpty);
                    }

                    if (_isGridView) {
                      return GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: filteredUrls.length,
                        itemBuilder: (context, index) {
                          final url = filteredUrls[index];
                          return _buildDismissibleCard(url, index, isGrid: true);
                        },
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      itemCount: filteredUrls.length,
                      itemBuilder: (context, index) {
                        final url = filteredUrls[index];
                        return _buildDismissibleCard(url, index, isGrid: false);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  ),
                  error: (err, _) {
                    String message = 'Failed to load URLs';
                    final errStr = err.toString();
                    if (errStr.contains('no-app') ||
                        errStr.contains('core/no-app') ||
                        errStr.contains('FirebaseApp')) {
                      message =
                          'Firebase Configuration Missing\n\nPlease add google-services.json (Android) or GoogleService-Info.plist (iOS) to set up connection.';
                    } else {
                      message = 'Error: $err';
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 48.sp,
                              color: Colors.redAccent.withOpacity(0.7),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedTab == 0) {
            _showUrlForm(context);
          } else {
            _showPasswordForm(context);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00F2FF), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _selectedTab == 0 ? Icons.add_rounded : Icons.add_moderator_rounded,
            color: Colors.black,
            size: 28.sp,
          ),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildSectionTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppTheme.neonCyan.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 0 ? AppTheme.neonCyan.withOpacity(0.6) : Colors.transparent,
                  ),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppTheme.neonCyan.withOpacity(0.15),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16.sp,
                      color: _selectedTab == 0 ? AppTheme.neonCyan : Colors.white54,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'URL Vault',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 0 ? AppTheme.neonCyan : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppTheme.neonPurple.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 1 ? AppTheme.neonPurple.withOpacity(0.6) : Colors.transparent,
                  ),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppTheme.neonPurple.withOpacity(0.15),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 16.sp,
                      color: _selectedTab == 1 ? AppTheme.neonPurple : Colors.white54,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Passwords',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 1 ? AppTheme.neonPurple : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(UrlModel url, int index, {required bool isGrid}) {
    return Dismissible(
      key: Key(url.id ?? url.url + index.toString()),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: AppTheme.neonCyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.share, color: AppTheme.neonCyan),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Share.share('${url.name}: ${url.url}');
          return false;
        } else {
          return await _confirmDelete(context, ref, url);
        }
      },
      child: isGrid ? _GridUrlCard(url: url) : _UrlCard(url: url),
    ).animate(delay: (index * 30).ms).fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.96, 0.96),
          curve: Curves.easeOut,
        );
  }

  Widget _buildDismissiblePasswordCard(UrlModel url, int index) {
    return Dismissible(
      key: Key('pass_${url.id ?? index.toString()}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: AppTheme.neonCyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.share, color: AppTheme.neonCyan),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Share.share('${url.name}: ${url.url}');
          return false;
        } else {
          return await _confirmDelete(context, ref, url);
        }
      },
      child: _PasswordCard(url: url),
    ).animate(delay: (index * 30).ms).fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.96, 0.96),
          curve: Curves.easeOut,
        );
  }

  Widget _buildLockedVaultScreen() {
    return PopScope(
      canPop: !_isVaultLocked,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _toggleVaultLock();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonCyan.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withOpacity(0.2),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 64.sp,
                    color: AppTheme.neonCyan,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Vault Locked',
                  style: GoogleFonts.outfit(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Biometric authentication required',
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
                SizedBox(height: 32.h),
                GestureDetector(
                  onTap: _toggleVaultLock,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FACFE), Color(0xFF00F2FF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint_rounded, color: Colors.black),
                        SizedBox(width: 8.w),
                        Text(
                          'Unlock Vault',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
      ),
    );
  }

  Widget _buildTopHeader(int totalCount) {
    return Container(
      margin: EdgeInsets.only(top: 48.h, left: 20.w, right: 20.w, bottom: 6.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.shield_outlined, color: AppTheme.neonCyan, size: 20.sp),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URL VAULT',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$totalCount CONNECTIONS ENCRYPTED',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonCyan,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (_selectedTab == 0)
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: Colors.white70,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isGridView = !_isGridView);
                      },
                      tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    ),
                  IconButton(
                    icon: Icon(
                      _isVaultLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: AppTheme.neonCyan,
                      size: 20.sp,
                    ),
                    onPressed: _toggleVaultLock,
                    tooltip: 'Lock Vault',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? AppTheme.neonCyan.withOpacity(0.6)
                    : Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _searchQuery.isNotEmpty
                      ? AppTheme.neonCyan.withOpacity(0.18)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _searchQuery.isNotEmpty
                      ? AppTheme.neonCyan
                      : Colors.white38,
                  size: 18.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedTab == 0 ? 'Search links, domain, notes...' : 'Search logins, username, website...',
                      hintStyle: TextStyle(
                        color: Colors.white30,
                        fontSize: 12.sp,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
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
              selectedColor: catColor.withOpacity(0.22),
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
        },
      ),
    );
  }

  Widget _buildEmptyState(bool hasUrlsInVault) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasUrlsInVault ? Icons.search_off_rounded : Icons.link_off_rounded,
              size: 50.sp,
              color: Colors.white10,
            ),
            SizedBox(height: 12.h),
            Text(
              hasUrlsInVault
                  ? 'No matching links found'
                  : 'Vault is empty',
              style: TextStyle(color: Colors.white38, fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              hasUrlsInVault
                  ? 'Try searching for another keyword or category'
                  : 'Tap the + button to save your first link',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12.sp),
            ),
            if (hasUrlsInVault) ...[
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'All';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'Reset Filters',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPasswordState(bool hasPasswords) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPasswords ? Icons.search_off_rounded : Icons.shield_outlined,
              size: 54.sp,
              color: Colors.white10,
            ),
            SizedBox(height: 12.h),
            Text(
              hasPasswords ? 'No matching passwords' : 'Password Vault is Empty',
              style: TextStyle(color: Colors.white38, fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              hasPasswords
                  ? 'Try searching for another keyword'
                  : 'Tap the + button to add your first encrypted login',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlForm(BuildContext context, [UrlModel? url]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UrlFormScreen(url: url),
    );
  }

  void _showPasswordForm(BuildContext context, [UrlModel? url]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PasswordFormScreen(url: url),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, UrlModel url) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Entry?'),
        content: Text('Are you sure you want to delete "${url.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteUrl(url.id!);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _PasswordCard extends ConsumerStatefulWidget {
  final UrlModel url;

  const _PasswordCard({required this.url});

  @override
  ConsumerState<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<_PasswordCard> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final host = Uri.tryParse(url.url)?.host ?? '';
    final faviconUrl = host.isNotEmpty
        ? 'https://www.google.com/s2/favicons?domain=$host&sz=64'
        : '';
    final initial = url.name.isNotEmpty ? url.name[0].toUpperCase() : '?';

    final decryptedPass = (url.password != null && url.password!.isNotEmpty)
        ? EncryptionService.decrypt(url.password!)
        : '';
    final strength = PasswordGeneratorService.calculateStrength(decryptedPass);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GlassCard(
        padding: EdgeInsets.all(16.w),
        borderRadius: 20,
        opacity: 0.12,
        borderGradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withOpacity(0.35),
            Colors.white.withOpacity(0.04),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.neonPurple.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonPurple.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: faviconUrl.isNotEmpty
                            ? Image.network(
                                faviconUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(child: Text(initial, style: TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold))),
                              )
                            : Center(child: Text(initial, style: TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          url.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (host.isNotEmpty)
                          Text(
                            host,
                            style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: strength.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: strength.color.withOpacity(0.4), width: 0.8),
                  ),
                  child: Text(
                    strength.label,
                    style: TextStyle(
                      color: strength.color,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Username Box
            if (url.username != null && url.username!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 14),
                        SizedBox(width: 8.w),
                        Text(
                          url.username!,
                          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: url.username!));
                        HapticFeedback.lightImpact();
                        ToastService.show(context, 'Username Copied');
                      },
                      child: const Icon(Icons.copy_rounded, color: AppTheme.neonCyan, size: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // Password Box
            if (decryptedPass.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: AppTheme.neonCyan, size: 14),
                        SizedBox(width: 8.w),
                        Text(
                          _obscurePassword ? '••••••••••••••••' : decryptedPass,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontFamily: _obscurePassword ? null : 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: decryptedPass));
                            HapticFeedback.lightImpact();
                            ToastService.show(context, 'Password Copied');
                          },
                          child: const Icon(Icons.key_rounded, color: AppTheme.neonCyan, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PasswordFormScreen(url: url),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: Colors.white38, size: 12),
                      SizedBox(width: 4.w),
                      Text('Edit', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                    ],
                  ),
                ),
                if (url.url.isNotEmpty && url.url.startsWith('http'))
                  GestureDetector(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(url.url.trim());
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new_rounded, color: AppTheme.neonCyan, size: 10),
                          SizedBox(width: 4.w),
                          Text(
                            'Open Site',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlCard extends ConsumerStatefulWidget {
  final UrlModel url;

  const _UrlCard({required this.url});

  @override
  ConsumerState<_UrlCard> createState() => _UrlCardState();
}

class _UrlCardState extends ConsumerState<_UrlCard> {
  bool _isCopied = false;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => _isCopied = true);
    ToastService.show(context, 'Copied');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final catColor = AppTheme.getCategoryColor(url.category);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GlassCard(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        borderRadius: 18,
        opacity: 0.08,
        borderGradient: LinearGradient(
          colors: [
            catColor.withOpacity(0.35),
            Colors.white.withOpacity(0.04),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFaviconBox(url),
                _buildActionIcons(context, ref),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    url.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (url.category.isNotEmpty && url.category != 'General') ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: catColor.withOpacity(0.35), width: 0.8),
                    ),
                    child: Text(
                      url.category,
                      style: TextStyle(
                        color: catColor,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (DateTime.now().difference(url.createdAt).inDays < 2) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        color: AppTheme.neonPurple,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              url.url,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.neonCyan.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (url.description.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                url.description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white38,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(url.createdAt),
                  style: TextStyle(color: Colors.white12, fontSize: 10.sp),
                ),
                _buildLaunchButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaviconBox(UrlModel url) {
    final host = Uri.tryParse(url.url)?.host ?? '';
    final faviconUrl = host.isNotEmpty
        ? 'https://www.google.com/s2/favicons?domain=$host&sz=64'
        : '';
    final initial = url.name.isNotEmpty ? url.name[0].toUpperCase() : '?';

    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: faviconUrl.isNotEmpty
            ? Image.network(
                faviconUrl,
                width: 36.w,
                height: 36.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialFallback(initial),
              )
            : _buildInitialFallback(initial),
      ),
    );
  }

  Widget _buildInitialFallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.neonCyan,
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context, WidgetRef ref) {
    final url = widget.url;
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final updated = url.copyWith(isFavorite: !url.isFavorite);
            await ref.read(firestoreServiceProvider).updateUrl(updated);
            if (context.mounted) {
              ToastService.show(
                context,
                updated.isFavorite ? 'Starred' : 'Unstarred',
              );
            }
          },
          child: Icon(
            url.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: url.isFavorite ? Colors.amber : Colors.white24,
            size: 18,
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: () {
            Share.share('${url.name}: ${url.url}');
          },
          child: const Icon(Icons.share_outlined, color: Colors.white24, size: 16),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: () => _copyToClipboard(url.url),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
              key: ValueKey(_isCopied),
              color: _isCopied ? const Color(0xFF00FF88) : Colors.white24,
              size: 16,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        _buildEditDeleteMenu(context, ref),
      ],
    );
  }

  Widget _buildEditDeleteMenu(BuildContext context, WidgetRef ref) {
    final url = widget.url;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white24, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => UrlFormScreen(url: url),
          );
        } else if (value == 'delete') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text('Delete Connection?'),
              content: Text('Are you sure you want to delete "${url.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(firestoreServiceProvider).deleteUrl(url.id!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildLaunchButton(BuildContext context) {
    final url = widget.url;
    return GestureDetector(
      onTap: () async {
        final urlString = url.url.trim();
        if (urlString.isEmpty) {
          ToastService.show(context, 'URL is empty', isError: true);
          return;
        }

        try {
          final uri = Uri.parse(urlString);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ToastService.show(context, 'Could not launch URL', isError: true);
            }
          }
        } catch (e) {
          if (context.mounted) {
            ToastService.show(context, 'Invalid URL format', isError: true);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FACFE), Color(0xFF00F2FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.black, size: 13),
            SizedBox(width: 4.w),
            Text(
              'Launch',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }
}

class _GridUrlCard extends ConsumerStatefulWidget {
  final UrlModel url;

  const _GridUrlCard({required this.url});

  @override
  ConsumerState<_GridUrlCard> createState() => _GridUrlCardState();
}

class _GridUrlCardState extends ConsumerState<_GridUrlCard> {
  bool _isCopied = false;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => _isCopied = true);
    ToastService.show(context, 'Copied');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final host = Uri.tryParse(url.url)?.host ?? '';
    final faviconUrl = host.isNotEmpty
        ? 'https://www.google.com/s2/favicons?domain=$host&sz=64'
        : '';
    final initial = url.name.isNotEmpty ? url.name[0].toUpperCase() : '?';
    final catColor = AppTheme.getCategoryColor(url.category);

    return GlassCard(
      padding: EdgeInsets.all(12.w),
      borderRadius: 16,
      opacity: 0.08,
      borderGradient: LinearGradient(
        colors: [
          catColor.withOpacity(0.35),
          Colors.white.withOpacity(0.04),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: faviconUrl.isNotEmpty
                      ? Image.network(
                          faviconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Text(initial, style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold))),
                        )
                      : Center(child: Text(initial, style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold))),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final updated = url.copyWith(isFavorite: !url.isFavorite);
                      await ref.read(firestoreServiceProvider).updateUrl(updated);
                    },
                    child: Icon(
                      url.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: url.isFavorite ? Colors.amber : Colors.white24,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () => _copyToClipboard(url.url),
                    child: Icon(
                      _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                      color: _isCopied ? const Color(0xFF00FF88) : Colors.white24,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                url.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                url.url,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: catColor.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              final urlString = url.url.trim();
              if (urlString.isEmpty) return;
              try {
                final uri = Uri.parse(urlString);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 5.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.black, size: 11),
                    SizedBox(width: 2.w),
                    Text(
                      'Launch',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
