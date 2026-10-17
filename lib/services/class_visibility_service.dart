import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_model.dart';
import '../models/user_model.dart';

class ClassVisibilityRule {
  final String scheduleId;
  final String type;
  final List<String> roles;
  final String courseId;
  final List<String> phones;

  const ClassVisibilityRule({
    required this.scheduleId,
    required this.type,
    this.roles = const [],
    this.courseId = '',
    this.phones = const [],
  });

  Map<String, dynamic> toJson() => {
        'scheduleId': scheduleId,
        'type': type,
        'roles': roles,
        'courseId': courseId,
        'phones': phones,
      };

  factory ClassVisibilityRule.fromJson(Map<String, dynamic> json) {
    return ClassVisibilityRule(
      scheduleId: json['scheduleId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'all_students',
      roles: List<String>.from((json['roles'] as List?) ?? const []),
      courseId: json['courseId']?.toString() ?? '',
      phones: List<String>.from((json['phones'] as List?) ?? const []),
    );
  }
}

class ClassVisibilityService {
  static const String _key = 'erfan_oxygen_class_visibility_v1';
  static final Map<String, ClassVisibilityRule> _rules = {};

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _rules.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        if (entry is Map) {
          final rule = ClassVisibilityRule.fromJson(Map<String, dynamic>.from(entry));
          _rules[rule.scheduleId] = rule;
        }
      }
    } catch (_) {
      _rules.clear();
    }
  }

  static ClassVisibilityRule? ruleFor(String scheduleId) => _rules[scheduleId];

  static List<ScheduleItem> visibleToUser(List<ScheduleItem> items, UserModel? user) {
    if (user == null) return const [];
    if (user.role == 'admin') return items.where((item) => item.active).toList();
    if (user.role == 'customer') return const [];
    return items.where((item) => item.active && isVisible(item, user)).toList();
  }

  static bool isVisible(ScheduleItem item, UserModel user) {
    final rule = _rules[item.id];
    if (rule == null || rule.type == 'all_students') return true;
    if (rule.type == 'roles') return rule.roles.contains(user.role);
    if (rule.type == 'course') return rule.courseId.isEmpty || (user.course ?? '') == rule.courseId;
    if (rule.type == 'users') return rule.phones.contains(user.phone);
    return true;
  }

  static Future<void> saveRule(ClassVisibilityRule rule) async {
    _rules[rule.scheduleId] = rule;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_rules.values.map((e) => e.toJson()).toList()));
  }

  static Future<void> removeRule(String scheduleId) async {
    _rules.remove(scheduleId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_rules.values.map((e) => e.toJson()).toList()));
  }
}
