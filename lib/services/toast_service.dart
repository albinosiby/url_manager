import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_theme.dart';

class ToastService {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isError
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : AppTheme.neonCyan.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.redAccent : AppTheme.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.only(bottom: 40, left: 60.w, right: 60.w),
      ),
    );
  }
}
