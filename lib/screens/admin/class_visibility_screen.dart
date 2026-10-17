import 'package:flutter/material.dart';

import '../../models/schedule_model.dart';
import '../../services/class_visibility_service.dart';
import '../../services/course_catalog_service.dart';
import '../../services/schedule_service.dart';
import '../../services/user_manager.dart';
import '../../theme/app_theme.dart';

class ClassVisibilityScreen extends StatefulWidget {
  final ScheduleItem? initialItem;

  const ClassVisibilityScreen({super.key, this.initialItem});

  @override
  State<ClassVisibilityScreen> createState() => _ClassVisibilityScreenState();
}

class _ClassVisibilityScreenState extends State<ClassVisibilityScreen> {
  ScheduleItem? selected;
  String type = 'all_students';
  final Set<String> roles = {'student'};
  String courseId = '';
  final Set<String> phones = {};

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadRule(item);
      });
    }
  }

  Future<void> _pickItem() async {
    final chosen = await showModalBottomSheet<ScheduleItem>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (context) => ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: ScheduleService.items.where((e) => e.active).map((item) => ListTile(title: Text(item.title), subtitle: Text('${item.day} • ${item.time}'), leading: const Icon(Icons.school_rounded, color: AppTheme.gold), onTap: () => Navigator.pop(context, item))).toList()),
    );
    if (!mounted || chosen == null) return;
    _loadRule(chosen);
  }

  void _loadRule(ScheduleItem item) {
    final rule = ClassVisibilityService.ruleFor(item.id);
    setState(() {
      selected = item;
      type = rule?.type ?? 'all_students';
      roles
        ..clear()
        ..addAll(rule?.roles ?? const ['student']);
      courseId = rule?.courseId ?? '';
      phones
        ..clear()
        ..addAll(rule?.phones ?? const []);
    });
  }

  Future<void> _save() async {
    final item = selected;
    if (item == null) return;
    if (type == 'roles' && roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک نقش را انتخاب کنید.')));
      return;
    }
    if (type == 'users' && phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک هنرجو را انتخاب کنید.')));
      return;
    }

    await ClassVisibilityService.saveRule(ClassVisibilityRule(scheduleId: item.id, type: type, roles: roles.toList(), courseId: courseId, phones: phones.toList()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قانون نمایش کلاس ذخیره شد.')));
  }

  @override
  Widget build(BuildContext context) {
    final students = UserManager.getUsersByRole('student');
    return OxygenPage(
      title: 'دسترسی کلاس‌ها',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          const PremiumHero(eyebrow: 'EXECUTIVE CONTROL', title: 'چه کسی این کلاس را ببیند؟', subtitle: 'نمایش هر کلاس را برای همه، نقش‌ها، یک دوره خاص یا چند کاربر مشخص کنترل کن.', icon: Icons.visibility_rounded, accentColor: AppTheme.gold2),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _pickItem, icon: const Icon(Icons.calendar_month_rounded), label: Text(selected == null ? 'انتخاب کلاس' : '${selected!.title} • ${selected!.day}')),
          if (selected != null) ...[
            const SizedBox(height: 16),
            _ChoiceTile(label: 'همه هنرجویان', value: 'all_students', groupValue: type, onChanged: (value) => setState(() => type = value)),
            _ChoiceTile(label: 'نقش‌های مشخص', value: 'roles', groupValue: type, onChanged: (value) => setState(() => type = value)),
            _ChoiceTile(label: 'دوره/گروه مشخص', value: 'course', groupValue: type, onChanged: (value) => setState(() => type = value)),
            _ChoiceTile(label: 'کاربران انتخاب‌شده', value: 'users', groupValue: type, onChanged: (value) => setState(() => type = value)),
            if (type == 'roles') ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _RoleChip(label: 'هنرجو', value: 'student', selected: roles.contains('student'), onTap: () => setState(() => roles.contains('student') ? roles.remove('student') : roles.add('student'))),
                _RoleChip(label: 'مدرس', value: 'teacher', selected: roles.contains('teacher'), onTap: () => setState(() => roles.contains('teacher') ? roles.remove('teacher') : roles.add('teacher'))),
              ]),
            ],
            if (type == 'course') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: courseId.isEmpty ? null : courseId, decoration: const InputDecoration(labelText: 'دوره'), items: CourseCatalogService.items.map((course) => DropdownMenuItem(value: course.id, child: Text(course.title))).toList(), onChanged: (value) => setState(() => courseId = value ?? '')),
            ],
            if (type == 'users') ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(14), decoration: AppTheme.glass(radius: 18), child: Column(children: students.map((student) => CheckboxListTile(contentPadding: EdgeInsets.zero, value: phones.contains(student.phone), title: Text(student.name), subtitle: Text(student.phone, style: const TextStyle(color: AppTheme.muted, fontSize: 11)), onChanged: (value) => setState(() => value == true ? phones.add(student.phone) : phones.remove(student.phone))).toList()))),
            ],
            const SizedBox(height: 16),
            SizedBox(height: 52, child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('ذخیره دسترسی کلاس'))),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _ChoiceTile({required this.label, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 8), decoration: AppTheme.glass(radius: 18), child: RadioListTile<String>(value: value, groupValue: groupValue, onChanged: (value) { if (value != null) onChanged(value); }, title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))));
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(key: ValueKey(value), selected: selected, onSelected: (_) => onTap(), label: Text(label), selectedColor: AppTheme.gold.withValues(alpha: .18), checkmarkColor: AppTheme.gold);
  }
}
