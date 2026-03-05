import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/saved_provider.dart';
import '../../models/job_model.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<JobModel> _jobs = [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final ids = context.read<SavedProvider>().savedIds.toList();
    if (ids.isEmpty) { setState(() { _jobs = []; _loading = false; }); return; }
    setState(() => _loading = true);
    try {
      final snaps = await Future.wait(ids.map((id) => FirebaseFirestore.instance.collection('jobs').doc(id).get()));
      final jobs = snaps.where((d) => d.exists).map((d) => JobModel.fromFirestore(d)).toList();
      if (mounted) setState(() { _jobs = jobs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SavedProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        automaticallyImplyLeading: false,
        actions: [if (_jobs.isNotEmpty) TextButton(onPressed: _load, child: const Text('Refresh', style: TextStyle(color: Colors.white)))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No saved jobs yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Tap the bookmark icon on any job to save it', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _jobs.length,
                  itemBuilder: (_, i) => JobCard(job: _jobs[i]),
                ),
    );
  }
}
