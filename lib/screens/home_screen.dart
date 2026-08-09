import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/url_model.dart';
import '../services/providers.dart';
import '../services/toast_service.dart';
import '../widgets/glass_card.dart';
import '../core/app_theme.dart';
import 'url_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final urlsAsync = ref.watch(urlsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildTopSearch(),
          Expanded(
            child: urlsAsync.when(
              data: (urls) {
                final filteredUrls = urls
                    .where(
                      (u) => u.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (filteredUrls.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: filteredUrls.length,
                  itemBuilder: (context, index) {
                    final url = filteredUrls[index];
                    return _UrlCard(url: url)
                        .animate(delay: (index * 50).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          curve: Curves.easeOut,
                        );
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
                          color: Colors.redAccent.withValues(alpha: 0.7),
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
                color: AppTheme.neonCyan.withValues(alpha: 0.4),
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

  Widget _buildTopSearch() {
    return Container(
      margin: EdgeInsets.only(top: 50.h, left: 20.w, right: 20.w, bottom: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search your links',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13.sp),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white24,
                  size: 18,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 50.sp, color: Colors.white10),
          SizedBox(height: 12.h),
          Text(
            'No links found',
            style: TextStyle(color: Colors.white24, fontSize: 16.sp),
          ),
        ],
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
}

class _UrlCard extends ConsumerWidget {
  final UrlModel url;

  const _UrlCard({required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = url.name.isNotEmpty ? url.name[0].toUpperCase() : '?';

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
                _buildIconBox(initial),
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
                if (DateTime.now().difference(url.createdAt).inDays < 2) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPurple.withValues(alpha: 0.15),
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
                color: AppTheme.neonCyan.withValues(alpha: 0.6),
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

  Widget _buildIconBox(String initial) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: url.url));
            ToastService.show(context, 'Copied');
          },
          child: const Icon(Icons.copy, color: Colors.white12, size: 16),
        ),
        SizedBox(width: 10.w),
        _buildEditDeleteMenu(context, ref),
      ],
    );
  }

  Widget _buildEditDeleteMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.white12, size: 18),
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
          _confirmDelete(context, ref);
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
              color: AppTheme.neonCyan.withValues(alpha: 0.1),
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete?'),
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
}
