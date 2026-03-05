import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jobs_provider.dart';
import '../../models/job_model.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<JobModel> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await context.read<JobsProvider>().search(q.trim());
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: (v) => Future.delayed(const Duration(milliseconds: 400), () {
            if (_ctrl.text == v) _search(v);
          }),
          decoration: InputDecoration(
            hintText: 'Search jobs, departments...',
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, color: Colors.white70), onPressed: () { _ctrl.clear(); setState(() => _results = []); })
                : null,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: AppTheme.primary,
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty && _ctrl.text.isEmpty
              ? _buildSuggestions()
              : _results.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text('No results for "${_ctrl.text}"', style: const TextStyle(color: AppTheme.textSecondary)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => JobCard(job: _results[i]),
                    ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = ['SSC CGL', 'Railway NTPC', 'UPSC Civil Services', 'Bank PO', 'Teacher Recruitment', 'Police Constable'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text('Popular Searches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) => GestureDetector(
            onTap: () { _ctrl.text = s; _search(s); },
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.trending_up, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
              ]),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
