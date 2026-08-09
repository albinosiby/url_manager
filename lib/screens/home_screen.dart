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
import '../widgets/glass_card.dart';
import '../core/app_theme.dart';
import 'url_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
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
        if (mounted)
          ToastService.show(context, 'Authentication Failed', isError: true);
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
          // Ambient Neon Backdrop Glows
          Positioned(
            top: -60.h,
            left: -60.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 120.h,
            right: -60.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonPurple.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            children: [
              _buildTopHeader(),
              _buildCategoryChips(),
              Expanded(
                child: urlsAsync.when(
                  data: (urls) {
                    final filteredUrls = urls.where((u) {
                      final matchesSearch =
                          u.name.toLowerCase().contains(
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
                          childAspectRatio: 0.95,
                        ),
                        itemCount: filteredUrls.length,
                        itemBuilder: (context, index) {
                          final url = filteredUrls[index];
                          return _buildDismissibleCard(
                            url,
                            index,
                            isGrid: true,
                          );
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
        onPressed: () => _showUrlForm(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: AppTheme.neonCyan,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        ),
      ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildDismissibleCard(
    UrlModel url,
    int index, {
    required bool isGrid,
  }) {
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
        )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOut);
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
                    border: Border.all(
                      color: AppTheme.neonCyan.withOpacity(0.3),
                    ),
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
                  'Biometric protection enabled',
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
                SizedBox(height: 32.h),
                GestureDetector(
                  onTap: _toggleVaultLock,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 14.h,
                    ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint, color: Colors.black),
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

  Widget _buildTopHeader() {
    return Container(
      margin: EdgeInsets.only(top: 50.h, left: 20.w, right: 20.w, bottom: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 32.h,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.link, color: AppTheme.neonCyan, size: 24.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'URL VAULT',
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: Colors.white70,
                      size: 20.sp,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    tooltip: _isGridView
                        ? 'Switch to List View'
                        : 'Switch to Grid View',
                  ),
                  IconButton(
                    icon: Icon(
                      _isVaultLocked ? Icons.lock : Icons.lock_open,
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
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? AppTheme.neonCyan.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _searchQuery.isNotEmpty
                      ? AppTheme.neonCyan.withOpacity(0.15)
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
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search links, domain, notes...',
                      hintStyle: TextStyle(
                        color: Colors.white30,
                        fontSize: 13.sp,
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
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          final catColor = AppTheme.getCategoryColor(cat);

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              avatar: cat == 'Favorites'
                  ? Icon(
                      Icons.star,
                      size: 14.sp,
                      color: isSelected
                          ? Colors.amber
                          : Colors.amber.withOpacity(0.6),
                    )
                  : null,
              label: Text(cat),
              selected: isSelected,
              selectedColor: catColor.withOpacity(0.2),
              backgroundColor: Colors.white.withOpacity(0.04),
              side: BorderSide(color: isSelected ? catColor : Colors.white10),
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
              hasUrlsInVault
                  ? Icons.search_off_rounded
                  : Icons.link_off_rounded,
              size: 50.sp,
              color: Colors.white10,
            ),
            SizedBox(height: 12.h),
            Text(
              hasUrlsInVault ? 'No matching links found' : 'Vault is empty',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
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

  void _showUrlForm(BuildContext context, [UrlModel? url]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UrlFormScreen(url: url),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UrlModel url,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Connection?'),
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
        borderRadius: 16,
        opacity: 0.08,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: catColor.withOpacity(0.3),
                        width: 0.8,
                      ),
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
                color: AppTheme.neonCyan.withOpacity(0.6),
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
                  color: Colors.white24,
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
      width: 34.w,
      height: 34.w,
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
                width: 34.w,
                height: 34.w,
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
            url.isFavorite ? Icons.star : Icons.star_border,
            color: url.isFavorite ? Colors.amber : Colors.white24,
            size: 18,
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () {
            Share.share('${url.name}: ${url.url}');
          },
          child: const Icon(
            Icons.share_outlined,
            color: Colors.white24,
            size: 16,
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () => _copyToClipboard(url.url),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isCopied ? Icons.check_circle : Icons.copy,
              key: ValueKey(_isCopied),
              color: _isCopied ? Color(0xFF00FF88) : Colors.white24,
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
      icon: const Icon(Icons.more_horiz, color: Colors.white24, size: 18),
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
              color: AppTheme.neonCyan.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: Colors.black, size: 12),
            SizedBox(width: 4.w),
            Text(
              'Launch',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
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
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: AppTheme.neonCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: AppTheme.neonCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final updated = url.copyWith(isFavorite: !url.isFavorite);
                      await ref
                          .read(firestoreServiceProvider)
                          .updateUrl(updated);
                    },
                    child: Icon(
                      url.isFavorite ? Icons.star : Icons.star_border,
                      color: url.isFavorite ? Colors.amber : Colors.white24,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () => _copyToClipboard(url.url),
                    child: Icon(
                      _isCopied ? Icons.check_circle : Icons.copy,
                      color: _isCopied
                          ? const Color(0xFF00FF88)
                          : Colors.white24,
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
              padding: EdgeInsets.symmetric(vertical: 4.h),
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
                    const Icon(Icons.bolt, color: Colors.black, size: 10),
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
