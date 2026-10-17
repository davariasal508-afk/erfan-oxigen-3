import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/course_catalog_service.dart';
import '../../services/course_enrollment_service.dart';
import '../../services/current_user.dart';
import '../../theme/app_theme.dart';

class EnrollmentRequestsScreen extends StatefulWidget {
  const EnrollmentRequestsScreen({super.key});

  @override
  State<EnrollmentRequestsScreen> createState() => _EnrollmentRequestsScreenState();
}

class _EnrollmentRequestsScreenState extends State<EnrollmentRequestsScreen> {
  String _price(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')} تومان';
  }

  Future<void> _approve(CourseEnrollmentRequest request) async {
    final ok = await CourseEnrollmentService.approve(request.id, CurrentUser.name.isEmpty ? 'عرفان' : CurrentUser.name);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'ثبت‌نام با موفقیت انجام شد.' : 'امکان تأیید وجود ندارد.')));
  }

  Future<void> _reject(CourseEnrollmentRequest request) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد درخواست ثبت‌نام'),
        content: TextField(controller: reasonController, maxLines: 3, decoration: const InputDecoration(labelText: 'دلیل رد (اختیاری)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, reasonController.text.trim()), child: const Text('رد درخواست')),
        ],
      ),
    );
    reasonController.dispose();
    if (!mounted || reason == null) return;
    final ok = await CourseEnrollmentService.reject(request.id, CurrentUser.name.isEmpty ? 'عرفان' : CurrentUser.name, reason: reason);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'درخواست رد شد.' : 'امکان رد درخواست وجود ندارد.')));
  }

  void _showReceipt(CourseEnrollmentRequest request) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glass(radius: 24, strong: true),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: request.receiptPath.isEmpty
                ? const Center(child: Text('رسید در دسترس نیست.'))
                : Image.file(File(request.receiptPath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = CourseEnrollmentService.requests.where((r) => r.status == 'pending').toList().reversed.toList();
    return OxygenPage(
      title: 'درخواست‌های ثبت‌نام',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          const PremiumHero(
            eyebrow: 'ACADEMY FINANCE',
            title: 'بررسی فیش‌های واریزی',
            subtitle: 'هر ثبت‌نام تا تأیید رسید در حالت انتظار باقی می‌ماند.',
            icon: Icons.receipt_long_rounded,
            accentColor: AppTheme.gold2,
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            Container(padding: const EdgeInsets.all(28), decoration: AppTheme.glass(radius: 22), child: const Column(children: [Icon(Icons.done_all_rounded, color: AppTheme.success, size: 48), SizedBox(height: 12), Text('درخواست در انتظار بررسی وجود ندارد', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('وقتی هنرجو یا مدرس رسیدی ارسال کند، اینجا نمایش داده می‌شود.', style: TextStyle(color: AppTheme.muted), textAlign: TextAlign.center)]))
          else
            ...pending.map((request) {
              final course = CourseCatalogService.byId(request.courseId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glass(radius: 22, strong: true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Container(width: 48, height: 48, decoration: AppTheme.goldGlow(radius: 14), child: const Icon(Icons.person_rounded, color: Colors.black)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.studentName, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(request.phone, style: const TextStyle(color: AppTheme.muted, fontSize: 11))])), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: .10), borderRadius: BorderRadius.circular(999)), child: const Text('PENDING', style: TextStyle(color: AppTheme.gold, fontSize: 9, fontWeight: FontWeight.w900)))]),
                      const SizedBox(height: 14),
                      Text(course?.title ?? request.courseId, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      Text('مبلغ: ${_price(request.amount)}', style: const TextStyle(color: AppTheme.muted)),
                      Text('تاریخ: ${request.createdAt.toLocal().toString().substring(0, 16)}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                      const SizedBox(height: 12),
                      if (request.receiptPath.isNotEmpty)
                        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(request.receiptPath), height: 160, width: double.infinity, fit: BoxFit.cover))
                      else
                        Container(height: 160, decoration: AppTheme.outlineGold(radius: 16), child: const Center(child: Text('تصویر رسید در دسترس نیست.'))),
                      const SizedBox(height: 10),
                      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _showReceipt(request), icon: const Icon(Icons.visibility_rounded), label: const Text('مشاهده رسید'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _approve(request), icon: const Icon(Icons.check_rounded), label: const Text('تأیید'))), const SizedBox(width: 8), IconButton(onPressed: () => _reject(request), tooltip: 'رد', icon: const Icon(Icons.close_rounded, color: AppTheme.danger))]),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
