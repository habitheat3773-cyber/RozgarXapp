import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../models/job_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<JobModel> _jobs = [];
  String? _error;

  final List<String> _categories = [
    'All', 'SSC', 'Railway', 'Banking', 'UPSC',
    'Defence', 'Teaching', 'Police', 'Engineering', 'Medical',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showFab) setState(() => _showFab = show);
    });
    _loadJobs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      Query query = FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('created_at', descending: true)
          .limit(50);
      if (_selectedCategory != 'All') {
        query = query.where('category', isEqualTo: _selectedCategory);
      }
      final snap = await query.get();
      setState(() {
        _jobs = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        color: const Color(0xFF1E3A8A),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            _buildCategoryFilter(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Could not load jobs', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadJobs,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A)),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_jobs.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No jobs found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _JobCard(job: _jobs[index]),
                    childCount: _jobs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF1E3A8A),
              onPressed: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF1E3A8A),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RozgarX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          Text('Sarkari Naukri, Ek Click Mein', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => context.go('/search'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _categories.length,
          itemBuilder: (context, i) {
            final cat = _categories[i];
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _loadJobs();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final daysLeft = job.daysLeft;
    final isUrgent = daysLeft != null && daysLeft <= 7 && daysLeft >= 0;
    final isExpired = job.isExpired;

    return GestureDetector(
      onTap: () => context.go('/job/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent
                ? Colors.orange.withOpacity(0.5)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      daysLeft == 0 ? 'Today!' : '${daysLeft}d left',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isExpired && !isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Expired',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              job.department,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (job.category != null) _chip(job.category!, const Color(0xFF1E3A8A)),
                const SizedBox(width: 6),
                if (job.totalPosts != null) _chip('${job.totalPosts} Posts', const Color(0xFF059669)),
                const Spacer(),
                if (job.lastDate != null)
                  Text(
                    'Last: ${job.lastDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUrgent ? Colors.orange : const Color(0xFF94A3B8),
                      fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
