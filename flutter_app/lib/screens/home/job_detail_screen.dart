import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_model.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../ai/ai_engine.dart';
import '../../core/services/admob_service.dart';
import '../../core/services/analytics_service.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/timeline_widget.dart';
import '../../widgets/preparation_tips_card.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  final JobModel? job;
  const JobDetailScreen({super.key, required this.jobId, this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _appBarCollapsed = false;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController()
      ..addListener(() {
        final collapsed = _scrollController.offset > 200;
        if (collapsed != _appBarCollapsed) {
          setState(() => _appBarCollapsed = collapsed);
        }
      });

    AnalyticsService.logJobView(widget.jobId, widget.job?.category ?? '');

    // Show interstitial after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_adShown) {
        _adShown = true;
        AdMobService.showInterstitialAd();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    if (job == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isSaved = ref.watch(savedJobsProvider).contains(job.id);
    final syllabus = AIEngine.extractSyllabus(job);
    final tips = AIEngine.generatePreparationTips(job);
    final urgencyPercent = (job.daysLeft / 30).clamp(0.0, 1.0);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          _buildSliverAppBar(ctx, job, isSaved),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(job, urgencyPercent),
                  _buildTimelineTab(job),
                  _buildSyllabusTab(syllabus),
                  _buildPreparationTab(tips),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(job),
    );
  }

  Widget _buildSliverAppBar(BuildContext ctx, JobModel job, bool isSaved) {
    final catColor = AppTheme.categoryColors[job.category] ?? AppTheme.primaryBlue;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      actions: [
        IconButton(
          onPressed: () => _shareJob(job),
          icon: const Icon(Icons.share_outlined, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            ref.read(savedJobsProvider.notifier).toggleSave(job.id);
          },
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_outline,
            color: isSaved ? AppTheme.accentOrange : Colors.white,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                catColor.withOpacity(0.9),
                AppTheme.primaryBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildBadge(job.category),
                      if (job.isNew) _buildBadge('🆕 NEW', color: AppTheme.successGreen),
                      if (job.isUrgent) _buildBadge('⚡ URGENT', color: AppTheme.errorRed),
                      if (job.isFeatured) _buildBadge('⭐ FEATURED', color: AppTheme.accentOrange),
                    ],
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  Text(
                    job.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    maxLines: 3,
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
                  const SizedBox(height: 6),
                  Text(
                    job.department,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Quick stats row
                  Row(
                    children: [
                      _buildQuickStat('${job.totalPosts}', 'Posts', Icons.people_outline),
                      const SizedBox(width: 20),
                      _buildQuickStat('${job.daysLeft}', 'Days Left', Icons.timer_outlined,
                          color: job.isUrgent ? AppTheme.accentOrange : null),
                      const SizedBox(width: 20),
                      _buildQuickStat(job.state, 'Location', Icons.location_on_outlined),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: '📋 Overview'),
          Tab(text: '📅 Timeline'),
          Tab(text: '📚 Syllabus'),
          Tab(text: '💡 Preparation'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(JobModel job, double urgencyPercent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Application Deadline', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${job.daysLeft} days left',
                        style: TextStyle(
                          color: job.isUrgent ? AppTheme.errorRed : AppTheme.successGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearPercentIndicator(
                    percent: (1 - urgencyPercent).clamp(0.0, 1.0),
                    lineHeight: 8,
                    backgroundColor: Colors.grey[200],
                    progressColor: job.isUrgent
                        ? AppTheme.errorRed
                        : job.daysLeft <= 7
                            ? AppTheme.warningAmber
                            : AppTheme.successGreen,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                    animation: true,
                    animationDuration: 1200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Date: ${DateFormat('dd MMMM yyyy').format(job.lastDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          // Job details grid
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 Job Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  InfoTile(label: 'Department', value: job.department, icon: Icons.business),
                  InfoTile(label: 'Category', value: job.category, icon: Icons.category_outlined),
                  InfoTile(label: 'Total Posts', value: '${job.totalPosts} Vacancies', icon: Icons.people_outline),
                  InfoTile(label: 'Qualification', value: job.qualification, icon: Icons.school_outlined),
                  InfoTile(label: 'Age Limit', value: job.ageLimit, icon: Icons.cake_outlined),
                  InfoTile(label: 'State', value: job.state, icon: Icons.location_on_outlined),
                  if (job.salaryRange != null)
                    InfoTile(label: 'Salary', value: job.salaryRange!, icon: Icons.currency_rupee),
                  if (job.payScale != null)
                    InfoTile(label: 'Pay Scale', value: job.payScale!, icon: Icons.money),
                  if (job.applicationFee != null)
                    InfoTile(label: 'Application Fee', value: job.applicationFee!, icon: Icons.payment_outlined),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 12),

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    style: const TextStyle(height: 1.7, fontSize: 14),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          // AI likelihood badge
          Card(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Insight', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          AIEngine.likelyToExtend(job)
                              ? '📅 Deadline may extend — apply early'
                              : '⚡ Apply before deadline — no extension expected',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(JobModel job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TimelineWidget(job: job),
    );
  }

  Widget _buildSyllabusTab(List<SyllabusTopic> syllabus) {
    if (syllabus.isEmpty) {
      return const Center(
        child: Text('Syllabus details not available.\nCheck official notification.', textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: syllabus.length,
      itemBuilder: (ctx, i) {
        final topic = syllabus[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700)),
            ),
            title: Text(topic.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: LinearPercentIndicator(
              percent: topic.relevance,
              lineHeight: 4,
              backgroundColor: Colors.grey[200],
              progressColor: AppTheme.primaryBlue,
              barRadius: const Radius.circular(2),
              padding: EdgeInsets.zero,
              animation: true,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: topic.subtopics.map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                  )).toList(),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 80).ms);
      },
    );
  }

  Widget _buildPreparationTab(List<String> tips) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PreparationTipsCard(tips: tips),
        const SizedBox(height: 16),
        // Official links
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.link, color: AppTheme.primaryBlue),
                title: const Text('Official Notification'),
                subtitle: const Text('Download original PDF'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _launchUrl(widget.job?.notificationLink ?? widget.job?.applyLink ?? ''),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.how_to_reg, color: AppTheme.successGreen),
                title: const Text('Apply Online'),
                subtitle: const Text('Official application portal'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  AnalyticsService.logJobApply(widget.jobId, widget.job?.category ?? '');
                  _launchUrl(widget.job?.applyLink ?? '');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(JobModel job) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  AnalyticsService.logJobApply(job.id, job.category);
                  _launchUrl(job.applyLink);
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Apply Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => context.go('/syllabus/${job.id}', extra: job),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(52, 52),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.menu_book_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryBlueLite).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? AppTheme.primaryBlueLite).withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(
        color: color ?? Colors.white,
        fontSize: 11, fontWeight: FontWeight.w600,
      )),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: (color ?? Colors.white).withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        ),
        Text(
          value.length > 12 ? '${value.substring(0, 12)}...' : value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _shareJob(JobModel job) {
    Share.share(
      'Check this job: ${job.title}\n${job.department}\n'
      '${job.totalPosts} Posts • Apply by ${DateFormat('dd MMM yyyy').format(job.lastDate)}\n'
      '${job.applyLink}\n\nDownload RozgarX app for more government jobs!',
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
