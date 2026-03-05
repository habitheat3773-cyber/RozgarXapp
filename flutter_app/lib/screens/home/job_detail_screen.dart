import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/saved_provider.dart';
import '../../models/job_model.dart';
import '../../core/theme/app_theme.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  JobModel? _job;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final job = await context.read<JobsProvider>().getJobById(widget.jobId);
    if (mounted) setState(() { _job = job; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_job == null) return Scaffold(appBar: AppBar(title: const Text('Not Found')), body: const Center(child: Text('Job not found')));

    final job = _job!;
    final saved = context.watch<SavedProvider>().isSaved(job.id);
    final daysLeft = job.daysLeft;
    final isUrgent = daysLeft >= 0 && daysLeft <= 7;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppTheme.primary,
            actions: [
              IconButton(
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline, color: Colors.white),
                onPressed: () => context.read<SavedProvider>().toggle(job.id),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => Share.share('${job.title}\n${job.department}\nLast: ${job.formattedLastDate}\n\nvia RozgarX'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: Text(daysLeft == 0 ? 'Last Day!' : '$daysLeft days left', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    Text(job.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(job.department, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Timeline'), Tab(text: 'Eligibility')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _overviewTab(job),
            _timelineTab(job),
            _eligibilityTab(job),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: () async {
            if (job.applyLink != null) {
              final uri = Uri.parse(job.applyLink!);
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String? value, IconData icon, Color color) {
    if (value == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab(JobModel job) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoTile('Total Posts', job.totalPosts?.toString(), Icons.people_outline, Colors.blue),
          _infoTile('Category', job.category, Icons.category_outlined, Colors.purple),
          _infoTile('Location', job.state ?? 'All India', Icons.location_on_outlined, Colors.green),
          _infoTile('Application Fee', job.applicationFee, Icons.payment_outlined, Colors.orange),
          _infoTile('Salary', job.salaryRange, Icons.currency_rupee, Colors.teal),
          if (job.description != null) ...[
            const SizedBox(height: 8),
            const Text('About This Job', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(job.description!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
          ],
        ],
      );

  Widget _timelineTab(JobModel job) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _timelineItem('Notification Date', job.formattedNotificationDate, Colors.blue, false),
          _timelineItem('Last Date to Apply', job.formattedLastDate, Colors.red, job.isExpired),
          _timelineItem('Admit Card', job.formattedAdmitCardDate, Colors.orange, false),
          _timelineItem('Exam Date', job.formattedExamDate, Colors.purple, false),
          _timelineItem('Result Date', job.formattedResultDate, Colors.teal, false),
        ],
      );

  Widget _timelineItem(String label, String? date, Color color, bool past) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: date != null ? (past ? Colors.grey : color) : Colors.grey.shade300, shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(date ?? 'To be announced', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: date != null ? (past ? Colors.grey : AppTheme.textPrimary) : Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _eligibilityTab(JobModel job) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoTile('Qualification', job.qualification, Icons.school_outlined, Colors.blue),
          _infoTile('Age Limit', job.ageLimit, Icons.cake_outlined, Colors.orange),
          const SizedBox(height: 12),
          const Text('How to Apply', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...[
            '1. Read the official notification carefully',
            '2. Check your eligibility criteria',
            '3. Collect all required documents',
            '4. Fill the application form online',
            '5. Upload photo and signature',
            '6. Pay the application fee',
            '7. Submit and save the confirmation',
          ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 14, height: 1.4))),
                ]),
              )),
        ],
      );
}
