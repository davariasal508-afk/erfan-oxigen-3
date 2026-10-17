import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'course_catalog_service.dart';

class CourseEnrollmentRequest {
  final String id;
  final String courseId;
  final String phone;
  final String studentName;
  final int amount;
  final String receiptPath;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const CourseEnrollmentRequest({
    required this.id,
    required this.courseId,
    required this.phone,
    required this.studentName,
    required this.amount,
    required this.receiptPath,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  CourseEnrollmentRequest copyWith({
    String? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return CourseEnrollmentRequest(
      id: id,
      courseId: courseId,
      phone: phone,
      studentName: studentName,
      amount: amount,
      receiptPath: receiptPath,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'phone': phone,
        'studentName': studentName,
        'amount': amount,
        'receiptPath': receiptPath,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewedBy': reviewedBy,
        'rejectionReason': rejectionReason,
      };

  factory CourseEnrollmentRequest.fromJson(Map<String, dynamic> json) {
    return CourseEnrollmentRequest(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.round() ?? 0,
      receiptPath: json['receiptPath']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      reviewedBy: json['reviewedBy']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class CourseEnrollmentService {
  static const String _key = 'erfan_oxygen_course_enrollments_v2';
  static final Map<String, List<String>> _enrollments = {};
  static final List<CourseEnrollmentRequest> requests = [];

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final legacyRaw = prefs.getString('erfan_oxygen_course_enrollments_v1');
    _enrollments.clear();
    requests.clear();
    if ((raw == null || raw.isEmpty) && (legacyRaw == null || legacyRaw.isEmpty)) return;

    try {
      if (raw == null || raw.isEmpty) {
        final legacyDecoded = jsonDecode(legacyRaw!) as Map<String, dynamic>;
        _enrollments.addAll(legacyDecoded.map((key, value) => MapEntry(key.toString(), List<String>.from(value as List<dynamic>))));
        await _save();
        return;
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final enrollmentData = decoded['enrollments'];
      if (enrollmentData is Map) {
        _enrollments.addAll(
          enrollmentData.map(
            (key, value) => MapEntry(
              key.toString(),
              List<String>.from(value as List<dynamic>),
            ),
          ),
        );
      }
      final requestData = decoded['requests'];
      if (requestData is List) {
        requests.addAll(
          requestData
              .whereType<Map>()
              .map((e) => CourseEnrollmentRequest.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    } catch (_) {
      _enrollments.clear();
      requests.clear();
    }
  }

  static List<String> enrolledPhones(String courseId) => List<String>.from(_enrollments[courseId] ?? const []);

  static int count(String courseId) => _enrollments[courseId]?.length ?? 0;

  static bool isEnrolled(String courseId, String phone) => _enrollments[courseId]?.contains(phone) ?? false;

  static bool hasPendingRequest(String courseId, String phone) {
    return requests.any((request) => request.courseId == courseId && request.phone == phone && request.status == 'pending');
  }

  static CourseEnrollmentRequest? pendingFor(String courseId, String phone) {
    for (final request in requests.reversed) {
      if (request.courseId == courseId && request.phone == phone && request.status == 'pending') return request;
    }
    return null;
  }

  static Future<bool> enroll(String courseId, String phone) async {
    final course = CourseCatalogService.byId(courseId);
    if (course == null) return false;
    if (isEnrolled(courseId, phone)) return true;
    if (count(courseId) >= course.capacity) return false;
    (_enrollments[courseId] ??= []).add(phone);
    await _save();
    return true;
  }

  static Future<bool> submitRequest({
    required String courseId,
    required String phone,
    required String studentName,
    required String receiptPath,
  }) async {
    final course = CourseCatalogService.byId(courseId);
    if (course == null || receiptPath.trim().isEmpty) return false;
    if (isEnrolled(courseId, phone)) return true;
    if (hasPendingRequest(courseId, phone)) return false;
    if (count(courseId) >= course.capacity) return false;

    requests.add(
      CourseEnrollmentRequest(
        id: 'enroll_${DateTime.now().microsecondsSinceEpoch}',
        courseId: courseId,
        phone: phone,
        studentName: studentName,
        amount: course.price,
        receiptPath: receiptPath,
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
    await _save();
    return true;
  }

  static Future<bool> approve(String requestId, String reviewedBy) async {
    final index = requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return false;
    final request = requests[index];
    if (request.status != 'pending') return false;

    final course = CourseCatalogService.byId(request.courseId);
    if (course == null || count(request.courseId) >= course.capacity) return false;

    if (!isEnrolled(request.courseId, request.phone)) {
      (_enrollments[request.courseId] ??= []).add(request.phone);
    }

    requests[index] = request.copyWith(
      status: 'approved',
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
    await _save();
    return true;
  }

  static Future<bool> reject(String requestId, String reviewedBy, {String? reason}) async {
    final index = requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return false;
    final request = requests[index];
    if (request.status != 'pending') return false;

    requests[index] = request.copyWith(
      status: 'rejected',
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
      rejectionReason: reason,
    );
    await _save();
    return true;
  }

  static Future<void> cancel(String courseId, String phone) async {
    _enrollments[courseId]?.remove(phone);
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'enrollments': _enrollments,
        'requests': requests.map((request) => request.toJson()).toList(),
      }),
    );
  }
}
