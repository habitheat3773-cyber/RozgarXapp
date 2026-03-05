import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String department;
  final String? category;
  final String? state;
  final String? qualification;
  final String? ageLimit;
  final int? totalPosts;
  final String? salaryRange;
  final String? applicationFee;
  final String? applyLink;
  final String? description;
  final DateTime lastDate;
  final DateTime? notificationDate;
  final DateTime? examDate;
  final DateTime? admitCardDate;
  final DateTime? resultDate;
  final DateTime createdAt;
  final bool isFeatured;
  final List<String> tags;

  const JobModel({
    required this.id,
    required this.title,
    required this.department,
    this.category,
    this.state,
    this.qualification,
    this.ageLimit,
    this.totalPosts,
    this.salaryRange,
    this.applicationFee,
    this.applyLink,
    this.description,
    required this.lastDate,
    this.notificationDate,
    this.examDate,
    this.admitCardDate,
    this.resultDate,
    required this.createdAt,
    this.isFeatured = false,
    this.tags = const [],
  });

  bool get isExpired => lastDate.isBefore(DateTime.now());
  int get daysLeft => lastDate.difference(DateTime.now()).inDays;

  String get formattedLastDate => _fmt(lastDate);
  String? get formattedExamDate => examDate != null ? _fmt(examDate!) : null;
  String? get formattedNotificationDate => notificationDate != null ? _fmt(notificationDate!) : null;
  String? get formattedAdmitCardDate => admitCardDate != null ? _fmt(admitCardDate!) : null;
  String? get formattedResultDate => resultDate != null ? _fmt(resultDate!) : null;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: d['title'] ?? '',
      department: d['department'] ?? '',
      category: d['category'],
      state: d['state'],
      qualification: d['qualification'],
      ageLimit: d['age_limit'],
      totalPosts: d['total_posts'],
      salaryRange: d['salary_range'],
      applicationFee: d['application_fee'],
      applyLink: d['apply_link'],
      description: d['description'],
      lastDate: _parseDate(d['last_date']),
      notificationDate: d['notification_date'] != null ? _parseDate(d['notification_date']) : null,
      examDate: d['exam_date'] != null ? _parseDate(d['exam_date']) : null,
      admitCardDate: d['admit_card_date'] != null ? _parseDate(d['admit_card_date']) : null,
      resultDate: d['result_date'] != null ? _parseDate(d['result_date']) : null,
      createdAt: d['created_at'] != null ? _parseDate(d['created_at']) : DateTime.now(),
      isFeatured: d['is_featured'] ?? false,
      tags: List<String>.from(d['tags'] ?? []),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now().add(const Duration(days: 30));
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'department': department,
        'category': category,
        'state': state,
        'qualification': qualification,
        'age_limit': ageLimit,
        'total_posts': totalPosts,
        'salary_range': salaryRange,
        'application_fee': applicationFee,
        'apply_link': applyLink,
        'description': description,
        'last_date': Timestamp.fromDate(lastDate),
        'notification_date': notificationDate != null ? Timestamp.fromDate(notificationDate!) : null,
        'exam_date': examDate != null ? Timestamp.fromDate(examDate!) : null,
        'admit_card_date': admitCardDate != null ? Timestamp.fromDate(admitCardDate!) : null,
        'result_date': resultDate != null ? Timestamp.fromDate(resultDate!) : null,
        'created_at': Timestamp.fromDate(createdAt),
        'is_featured': isFeatured,
        'tags': tags,
      };
}
