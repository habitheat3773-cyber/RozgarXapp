import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/job_model.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/job_card.dart';
import '../../widgets/featured_banner.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/stats_banner.dart';
import '../../widgets/trending_section.dart';
import '../../widgets/skeleton_job_card.dart';
import '../../core/services/admob_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showFab) setState(() => _showFab = show);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final jobsAsync = ref.watch(jobsStreamProvider(_selectedCategory));
    final featuredAsync = ref.watch(featuredJobsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LiquidPullToRefresh(
        onRefresh: () async {
          ref.invalidate(jobsStreamProvider(_selectedCategory));
          ref.invalidate(featuredJobsProvider);
        },
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
        height: 80,
        animSpeedFactor: 2,
        showChildOpacityTransition: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────
            _buildSliverAppBar(context, user?.name ?? ''),

            // ── Stats Banner ─────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: StatsBanner(),
              ),
            ),

            // ── Category Filter ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: CategoryFilter(
                selected: _selectedCategory,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
            ),

            // ── Featured Jobs ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: featuredAsync.when(
                data: (jobs) => jobs.isEmpty
                    ? const SizedBox.shrink()
                    : _buildFeaturedSection(jobs),
                loading: () => _buildFeaturedSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Trending Section ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: TrendingSection(),
            ),

            // ── Jobs Header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'All' ? '📋 Latest Jobs' : '📋 $_selectedCategory Jobs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/search'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Jobs List ─────────────────────────────────────────────────
            jobsAsync.when(
              data: (jobs) => _buildJobsList(jobs),
              loading: () => _buildJobsSkeleton(),
              error: (err, _) => SliverToBoxAdapter(
                child: _buildErrorWidget(err),
              ),
            ),

            // ── Ad Banner ────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: BannerAdWidget()),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFab ? 1 : 0,
          child: FloatingActionButton(
            onPressed: () => _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            ),
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: 130,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        name.isNotEmpty ? name : 'Candidate 👋',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideX(begin: -0.1),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/notifications'),
                        icon: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, size: 28),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryBlue,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(List<JobModel> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🔥 Featured Jobs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: jobs.length,
            itemBuilder: (ctx, i) => FeaturedBanner(
              job: jobs[i],
              index: i,
              onTap: () => context.go('/job/${jobs[i].id}', extra: jobs[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSkeleton() {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  SliverList _buildJobsList(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          // Insert native ad every 5 jobs
          if (i > 0 && i % 6 == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: BannerAdWidget(size: AdSize.mediumRectangle),
            );
          }
          final jobIndex = i - (i ~/ 6);
          if (jobIndex >= jobs.length) return null;
          final job = jobs[jobIndex];
          return AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: JobCard(
                    job: job,
                    onTap: () => context.go('/job/${job.id}', extra: job),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: jobs.length + (jobs.length ~/ 6),
      ),
    );
  }

  SliverList _buildJobsSkeleton() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SkeletonJobCard(),
        ),
        childCount: 6,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.work_off_outlined, size: 72, color: Colors.grey[400])
              .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the category filter',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object err) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 56, color: AppTheme.errorRed),
          const SizedBox(height: 12),
          const Text('Failed to load jobs'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(jobsStreamProvider(_selectedCategory)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
