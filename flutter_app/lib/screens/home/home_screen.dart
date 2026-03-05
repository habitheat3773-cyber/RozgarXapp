import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/saved_provider.dart';
import '../../models/job_model.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > 400;
      if (show != _showFab) setState(() => _showFab = show);
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<JobsProvider>().loadJobs();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobsProvider>().loadJobs(refresh: true);
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => context.read<JobsProvider>().loadJobs(refresh: true),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            _AppBar(),
            _CategoryBar(),
            _JobsList(),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.small(
              backgroundColor: AppTheme.primary,
              onPressed: () => _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.primary,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('RozgarX', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('Sarkari Naukri, Ek Click Mein', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 26),
                onPressed: () => context.go('/search'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryDelegate(),
    );
  }
}

class _CategoryDelegate extends SliverPersistentHeaderDelegate {
  @override double get minExtent => 52;
  @override double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final provider = context.watch<JobsProvider>();
    return Container(
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: provider.categories.length,
        itemBuilder: (context, i) {
          final cat = provider.categories[i];
          final sel = cat == provider.selectedCategory;
          return GestureDetector(
            onTap: () => context.read<JobsProvider>().setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppTheme.primary : Colors.transparent),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: sel ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}

class _JobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobsProvider>();

    if (provider.isLoading && provider.jobs.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const _ShimmerCard(),
            childCount: 6,
          ),
        ),
      );
    }

    if (provider.error != null && provider.jobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(provider.error!, style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<JobsProvider>().loadJobs(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.jobs.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_off_rounded, size: 64, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text('No jobs found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == provider.jobs.length) {
              return provider.hasMore
                  ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  : const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('All jobs loaded', style: TextStyle(color: AppTheme.textSecondary))));
            }
            return JobCard(job: provider.jobs[i]);
          },
          childCount: provider.jobs.length + 1,
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final JobModel job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final daysLeft = job.daysLeft;
    final isUrgent = daysLeft >= 0 && daysLeft <= 7;
    final saved = context.watch<SavedProvider>().isSaved(job.id);

    return GestureDetector(
      onTap: () => context.go('/job/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUrgent ? Colors.orange.shade200 : AppTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            if (job.isFeatured)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Center(child: Text('⭐ Featured Job', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600))),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(job.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.read<SavedProvider>().toggle(job.id),
                        child: Icon(saved ? Icons.bookmark : Icons.bookmark_outline,
                            color: saved ? AppTheme.primary : AppTheme.textSecondary, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(job.department, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (job.category != null) _tag(job.category!, AppTheme.primary),
                      if (job.totalPosts != null) ...[const SizedBox(width: 6), _tag('${job.totalPosts} Posts', AppTheme.success)],
                      if (job.state != null) ...[const SizedBox(width: 6), _tag(job.state!, Colors.purple)],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('Last Date: ${job.formattedLastDate}',
                          style: TextStyle(fontSize: 12, color: isUrgent ? Colors.orange.shade700 : AppTheme.textSecondary, fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal)),
                      const Spacer(),
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                          child: Text(daysLeft == 0 ? 'Today!' : '${daysLeft}d left',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else if (job.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Expired', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 130,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
