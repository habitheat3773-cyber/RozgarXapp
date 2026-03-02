import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/job_model.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  JobModel? _job;
  bool _isLoading = true;
  bool _isSaved = false;
  Set<String> _savedJobs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadJob();
    _loadSavedJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _job = JobModel.fromFirestore(doc);
          _isLoading = false;
        });
        // Track view
        FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .update({'view_count': FieldValue.increment(1)});
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_jobs') ?? [];
    setState(() {
      _savedJobs = saved.toSet();
      _isSaved = _savedJobs.contains(widget.jobId);
    });
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_isSaved) {
        _savedJobs.remove(widget.jobId);
        _isSaved = false;
      } else {
        _savedJobs.add(widget.jobId);
        _isSaved = true;
      }
    });
    await prefs.setStringList('saved_jobs', _savedJobs.toList());
  }

  Future<void> _applyNow() async {
    if (_job?.applyLink == null) return;
    final uri = Uri.parse(_job!.applyLink!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({'apply_click_count': FieldValue.increment(1)});
    }
  }

  void _shareJob() {
    if (_job == null) return;
    Share.share(
      '${_job!.title}\n${_job!.department}\nLast Date: ${_job!.lastDate}\n\nDownload RozgarX for more govt jobs!',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Not Found')),
        body: const Center(child: Text('This job is no longer available.')),
      );
    }

    final job = _job!;
    final daysLeft = job.daysLeft;
    final isUrgent = daysLeft != null && daysLeft <= 7 && daysLeft >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            actions: [
              IconButton(
                icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white),
                onPressed: _toggleSave,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareJob,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          daysLeft == 0
                              ? 'Last Day!'
                              : '$daysLeft days left',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      job.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.department,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Timeline'),
                Tab(text: 'Eligibility'),
                Tab(text: 'Preparation'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(job),
                _buildTimelineTab(job),
                _buildEligibilityTab(job),
                _buildPreparationTab(job),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)
          ],
        ),
        child: ElevatedButton(
          onPressed: _applyNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Apply Now',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(JobModel job) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard('Total Posts', job.totalPosts?.toString() ?? 'N/A',
            Icons.people, Colors.blue),
        _infoCard('Category', job.category ?? 'General', Icons.category,
            Colors.purple),
        _infoCard('State', job.state ?? 'All India', Icons.location_on,
            Colors.green),
        _infoCard('Application Fee', job.applicationFee ?? 'Check Official',
            Icons.payment, Colors.orange),
        _infoCard('Salary', job.salaryRange ?? 'As per norms', Icons.currency_rupee,
            Colors.teal),
        if (job.description != null) ...[
          const SizedBox(height: 16),
          const Text('Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(job.description!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        ],
      ],
    );
  }

  Widget _buildTimelineTab(JobModel job) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _timelineItem('Notification Date', job.notificationDate, Colors.blue),
        _timelineItem('Apply Start', job.notificationDate, Colors.green),
        _timelineItem('Last Date to Apply', job.lastDate, Colors.red),
        _timelineItem('Admit Card', job.admitCardDate, Colors.orange),
        _timelineItem('Exam Date', job.examDate, Colors.purple),
        _timelineItem('Result Date', job.resultDate, Colors.teal),
      ],
    );
  }

  Widget _buildEligibilityTab(JobModel job) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard('Qualification', job.qualification ?? 'See notification',
            Icons.school, Colors.blue),
        _infoCard('Age Limit', job.ageLimit ?? 'See notification',
            Icons.cake, Colors.orange),
        const SizedBox(height: 16),
        const Text('How to Apply',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          '1. Read the official notification carefully\n'
          '2. Check your eligibility criteria\n'
          '3. Gather required documents\n'
          '4. Fill the application form online\n'
          '5. Upload photo & signature\n'
          '6. Pay application fee\n'
          '7. Submit and save confirmation',
          style: TextStyle(fontSize: 14, height: 1.8),
        ),
      ],
    );
  }

  Widget _buildPreparationTab(JobModel job) {
    final tips = _getTips(job.category);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Study Topics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tips
            .map((tip) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF22C55E), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String label, String? date, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: date != null ? color : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                Text(
                  date ?? 'To be announced',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null ? const Color(0xFF0F172A) : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTips(String? category) {
    switch (category?.toLowerCase()) {
      case 'ssc':
        return [
          'General Awareness & Current Affairs',
          'Quantitative Aptitude',
          'English Language',
          'General Intelligence & Reasoning',
        ];
      case 'railway':
        return [
          'Mathematics',
          'General Intelligence',
          'General Awareness',
          'General Science',
        ];
      case 'banking':
        return [
          'Quantitative Aptitude',
          'Reasoning Ability',
          'English Language',
          'General/Financial Awareness',
          'Computer Knowledge',
        ];
      case 'upsc':
        return [
          'History & Culture',
          'Geography',
          'Indian Polity & Governance',
          'Economy',
          'Science & Technology',
          'Current Affairs',
          'Essay Writing',
        ];
      default:
        return [
          'General Knowledge & Current Affairs',
          'Quantitative Aptitude',
          'Reasoning & Logical Thinking',
          'English Language',
          'General Science',
        ];
    }
  }
}
