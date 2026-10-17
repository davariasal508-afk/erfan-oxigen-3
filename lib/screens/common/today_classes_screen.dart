import 'package:flutter/material.dart';

import '../../models/schedule_model.dart';
import '../../services/class_visibility_service.dart';
import '../../services/current_user.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';

class TodayClassesScreen extends StatelessWidget {
  const TodayClassesScreen({super.key});

  String _todayName() {
    const names = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'];
    return names[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final user = CurrentUser.user;
    final today = _todayName();
    final classes = ClassVisibilityService.visibleToUser(ScheduleService.items, user).where((item) => item.day == today).toList();

    return OxygenPage(
      title: 'کلاس‌های امروز',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          PremiumHero(
            eyebrow: 'TODAY • ACADEMY',
            title: 'کلاس‌های امروز',
            subtitle: 'فقط کلاس‌هایی که برای حساب شما مجاز هستند نمایش داده می‌شوند.',
            icon: Icons.today_rounded,
            accentColor: AppTheme.gold2,
          ),
          const SizedBox(height: 16),
          if (classes.isEmpty)
            Container(padding: const EdgeInsets.all(28), decoration: AppTheme.glass(radius: 22), child: Column(children: [const Icon(Icons.event_busy_rounded, color: AppTheme.muted, size: 48), const SizedBox(height: 12), Text('برای امروز ($today) کلاسی برای شما ثبت نشده است.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('در صورت تغییر برنامه، اعلان مربوط به شما نمایش داده می‌شود.', style: TextStyle(color: AppTheme.muted), textAlign: TextAlign.center)]))
          else
            ...classes.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ClassCard(item: item))),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ScheduleItem item;

  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: AppTheme.glass(radius: 22, strong: true),
      child: Row(
        children: [
          Container(width: 58, height: 58, decoration: AppTheme.goldGlow(radius: 16), child: const Icon(Icons.school_rounded, color: Colors.black)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 6), Text('${item.day} • ${item.time}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)), if (item.room.isNotEmpty) ...[const SizedBox(height: 3), Text(item.room, style: const TextStyle(color: AppTheme.muted, fontSize: 11))]])),
          IconButton(onPressed: () => _showDetails(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17)),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 10), Text('${item.day} • ${item.time}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800)), if (item.room.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text('محل برگزاری: ${item.room}', style: const TextStyle(color: AppTheme.muted))), if (item.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(item.notes, style: const TextStyle(color: Colors.white70, height: 1.5))), const SizedBox(height: 18), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('بستن')))]),
      ),
    );
  }
}
