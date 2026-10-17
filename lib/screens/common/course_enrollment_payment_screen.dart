import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/course_catalog_service.dart';
import '../../services/course_enrollment_service.dart';
import '../../services/current_user.dart';
import '../../theme/app_theme.dart';

class CourseEnrollmentPaymentScreen extends StatefulWidget {
  final CourseCatalogItem course;

  const CourseEnrollmentPaymentScreen({super.key, required this.course});

  @override
  State<CourseEnrollmentPaymentScreen> createState() => _CourseEnrollmentPaymentScreenState();
}

class _CourseEnrollmentPaymentScreenState extends State<CourseEnrollmentPaymentScreen> {
  String? receiptPath;
  bool loading = false;
  bool submitted = false;

  String _price(int value) {
    final formatted = value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '$formatted تومان';
  }

  Future<void> _pickReceipt() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (!mounted || image == null) return;
    setState(() => receiptPath = image.path);
  }

  Future<void> _submit() async {
    if (receiptPath == null || receiptPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا رسید پرداخت را انتخاب کنید.')));
      return;
    }
    setState(() => loading = true);
    final ok = await CourseEnrollmentService.submitRequest(
      courseId: widget.course.id,
      phone: CurrentUser.phone,
      studentName: CurrentUser.name,
      receiptPath: receiptPath!,
    );
    if (!mounted) return;
    setState(() {
      loading = false;
      submitted = ok || CourseEnrollmentService.hasPendingRequest(widget.course.id, CurrentUser.phone);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'درخواست ثبت شد و منتظر تأیید مدیر است.' : 'درخواست دیگری برای این دوره در حال بررسی است یا ظرفیت تکمیل شده است.')));
  }

  @override
  Widget build(BuildContext context) {
    final pending = CourseEnrollmentService.pendingFor(widget.course.id, CurrentUser.phone);
    final enrolled = CourseEnrollmentService.isEnrolled(widget.course.id, CurrentUser.phone);

    return OxygenPage(
      title: 'ثبت‌نام دوره',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppTheme.glass(radius: 28, strong: true),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: .06,
                    child: Image.asset('assets/images/oxigen_shield_mark.png', fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 54, height: 54, decoration: AppTheme.goldGlow(radius: 16), child: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/images/oxigen_shield_mark.png'))),
                          const SizedBox(width: 14),
                          Expanded(child: Text(widget.course.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(widget.course.subtitle, style: const TextStyle(color: AppTheme.muted, height: 1.5)),
                      const SizedBox(height: 18),
                      _InfoRow(icon: Icons.school_rounded, label: 'مسیر', value: widget.course.category),
                      _InfoRow(icon: Icons.event_note_rounded, label: 'جلسات', value: widget.course.sessions),
                      _InfoRow(icon: Icons.groups_rounded, label: 'ظرفیت', value: '${widget.course.capacity} نفر'),
                      const SizedBox(height: 8),
                      Row(children: [const Text('مبلغ پرداختی', style: TextStyle(color: AppTheme.muted)), const Spacer(), Text(_price(widget.course.price), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900, fontSize: 20))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.glass(radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('رسید پرداخت', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 7),
                const Text('تصویر واضح رسید را بارگذاری کن تا مدیر آن را بررسی کند.', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                const SizedBox(height: 14),
                if (receiptPath != null)
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(receiptPath!), height: 230, fit: BoxFit.cover))
                else
                  Container(height: 210, decoration: AppTheme.outlineGold(radius: 18), child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_rounded, color: AppTheme.gold, size: 42), SizedBox(height: 8), Text('هنوز رسیدی انتخاب نشده', style: TextStyle(color: AppTheme.muted))]))),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: loading || enrolled ? null : _pickReceipt, icon: const Icon(Icons.upload_file_rounded), label: Text(receiptPath == null ? 'انتخاب رسید' : 'تعویض رسید')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (enrolled)
            _StatusCard(icon: Icons.verified_rounded, color: AppTheme.success, title: 'ثبت‌نام شما انجام شده است', subtitle: 'این دوره در فهرست دوره‌های ثبت‌نام‌شده شما قرار دارد.')
          else if (pending != null || submitted)
            _StatusCard(icon: Icons.hourglass_top_rounded, color: AppTheme.gold, title: 'در انتظار تأیید مدیر', subtitle: 'پس از بررسی رسید، در صورت تأیید ثبت‌نام نهایی می‌شود.')
          else
            SizedBox(height: 54, child: ElevatedButton.icon(onPressed: loading ? null : _submit, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.send_rounded), label: Text(loading ? 'در حال ارسال...' : 'ارسال درخواست ثبت‌نام'))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [Icon(icon, size: 18, color: AppTheme.gold), const SizedBox(width: 9), Text('$label: ', style: const TextStyle(color: AppTheme.muted)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)))]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusCard({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .22))),
      child: Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12))]))]),
    );
  }
}
