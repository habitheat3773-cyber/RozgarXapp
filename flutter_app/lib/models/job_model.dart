import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus { active, expired, upcoming }

class JobModel {
  final String id;
  final String title;
  final String department;
  final String category;
  final String state;
  final String qualification;
  final String ageLimit;
  final int totalPosts;
  final DateTime lastDate;
  final DateTime? notificationDate;
  final DateTime? examDate;
  final DateTime? resultDate;
  final DateTime? admitCardDate;
  final String applyLink;
  final String notificationLink;
  final String description;
  final DateTime createdAt;
  final String sourceUrl;
  final bool isFeatured;
  final String? applicationFee;
  final String? salaryRange;
  final String? payScale;
  final List<String> tags;
  final Map<String, dynamic> extraData;
  final int viewCount;
  final int applyClickCount;
  final bool autoAdded;

  JobModel({
    required this.id,
    required this.title,
    required this.department,
    required this.category,
    required this.state,
    required this.qualification,
    required this.ageLimit,
    required this.totalPosts,
    required this.lastDate,
    this.notificationDate,
    this.examDate,
    this.resultDate,
    this.admitCardDate,
    required this.applyLink,
    this.notificationLink = '',
    required this.description,
    required this.createdAt,
    required this.sourceUrl,
    this.isFeatured = false,
    this.applicationFee,
    this.salaryRange,
    this.payScale,
    this.tags = const [],
    this.extraData = const {},
    this.viewCount = 0,
    this.applyClickCount = 0,
    this.autoAdded = true,
  });

  bool get isExpired => lastDate.isBefore(DateTime.now());
  int get daysLeft => lastDate.difference(DateTime.now()).inDays;
  bool get isUrgent => daysLeft >= 0 && daysLeft <= 5;
  bool get isNew => DateTime.now().difference(createdAt).inDays <= 2;

  JobStatus get status {
    if (notificationDate != null && notificationDate!.isAfter(DateTime.now())) {
      return JobStatus.upcoming;
    }
    if (isExpired) return JobStatus.expired;
    return JobStatus.active;
  }

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: d['title'] ?? '',
      department: d['department'] ?? '',
      category: d['category'] ?? 'Other',
      state: d['state'] ?? 'All India',
      qualification: d['qualification'] ?? '',
      ageLimit: d['age_limit'] ?? '',
      totalPosts: d['total_posts'] ?? 0,
      lastDate: _parseDate(d['last_date']),
      notificationDate: d['notification_date'] != null ? _parseDate(d['notification_date']) : null,
      examDate: d['exam_date'] != null ? _parseDate(d['exam_date']) : null,
      resultDate: d['result_date'] != null ? _parseDate(d['result_date']) : null,
      admitCardDate: d['admit_card_date'] != null ? _parseDate(d['admit_card_date']) : null,
      applyLink: d['apply_link'] ?? '',
      notificationLink: d['notification_link'] ?? '',
      description: d['description'] ?? '',
      createdAt: d['created_at'] != null ? _parseDate(d['created_at']) : DateTime.now(),
      sourceUrl: d['source_url'] ?? '',
      isFeatured: d['is_featured'] ?? false,
      applicationFee: d['application_fee'],
      salaryRange: d['salary_range'],
      payScale: d['pay_scale'],
      tags: List<String>.from(d['tags'] ?? []),
      extraData: Map<String, dynamic>.from(d['extra_data'] ?? {}),
      viewCount: d['view_count'] ?? 0,
      applyClickCount: d['apply_click_count'] ?? 0,
      autoAdded: d['auto_added'] ?? true,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'department': department,
    'category': category,
    'state': state,
    'qualification': qualification,
    'age_limit': ageLimit,
    'total_posts': totalPosts,
    'last_date': Timestamp.fromDate(lastDate),
    'notification_date': notificationDate != null ? Timestamp.fromDate(notificationDate!) : null,
    'exam_date': examDate != null ? Timestamp.fromDate(examDate!) : null,
    'result_date': resultDate != null ? Timestamp.fromDate(resultDate!) : null,
    'admit_card_date': admitCardDate != null ? Timestamp.fromDate(admitCardDate!) : null,
    'apply_link': applyLink,
    'notification_link': notificationLink,
    'description': description,
    'created_at': Timestamp.fromDate(createdAt),
    'source_url': sourceUrl,
    'is_featured': isFeatured,
    'application_fee': applicationFee,
    'salary_range': salaryRange,
    'pay_scale': payScale,
    'tags': tags,
    'extra_data': extraData,
    'view_count': viewCount,
    'apply_click_count': applyClickCount,
    'auto_added': autoAdded,
  };

  JobModel copyWith({
    bool? isFeatured,
    int? viewCount,
    int? applyClickCount,
  }) {
    return JobModel(
      id: id, title: title, department: department, category: category,
      state: state, qualification: qualification, ageLimit: ageLimit,
      totalPosts: totalPosts, lastDate: lastDate, applyLink: applyLink,
      description: description, createdAt: createdAt, sourceUrl: sourceUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      applyClickCount: applyClickCount ?? this.applyClickCount,
      applicationFee: applicationFee, salaryRange: salaryRange,
      payScale: payScale, tags: tags, extraData: extraData,
      autoAdded: autoAdded,
    );
  }
}
