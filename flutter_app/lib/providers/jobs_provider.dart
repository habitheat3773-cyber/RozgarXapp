import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobsProvider extends ChangeNotifier {
  List<JobModel> _jobs = [];
  List<JobModel> _featured = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  List<JobModel> get jobs => _jobs;
  List<JobModel> get featured => _featured;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  bool get hasMore => _hasMore;

  final List<String> categories = [
    'All', 'SSC', 'Railway', 'Banking', 'UPSC',
    'Defence', 'Teaching', 'Police', 'Engineering', 'Medical', 'State PSC',
  ];

  Future<void> loadJobs({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _jobs = [];
      _lastDoc = null;
      _hasMore = true;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query q = FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('created_at', descending: true)
          .limit(20);

      if (_selectedCategory != 'All') {
        q = q.where('category', isEqualTo: _selectedCategory);
      }
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

      final snap = await q.get();
      if (snap.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDoc = snap.docs.last;
        final newJobs = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
        _jobs = refresh ? newJobs : [..._jobs, ...newJobs];
        _hasMore = snap.docs.length == 20;
      }

      if (refresh) await _loadFeatured();
    } catch (e) {
      _error = 'Failed to load jobs. Check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFeatured() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('jobs')
          .where('is_featured', isEqualTo: true)
          .limit(5)
          .get();
      _featured = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
    } catch (_) {}
  }

  void setCategory(String cat) {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    loadJobs(refresh: true);
  }

  Future<List<JobModel>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();
      return snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<JobModel?> getJobById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(id).get();
      if (doc.exists) return JobModel.fromFirestore(doc);
    } catch (_) {}
    return null;
  }
}
