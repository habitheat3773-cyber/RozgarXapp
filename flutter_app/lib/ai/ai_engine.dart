import '../models/job_model.dart';
import '../models/user_model.dart';

/// RozgarX AI Engine
/// Provides intelligent job matching, scoring, and recommendations
/// WITHOUT any external AI API — pure rule-based intelligence
class AIEngine {
  // ─── Job Relevance Scoring ─────────────────────────────────────────────────
  /// Score 0-100 how relevant a job is for a user
  static double scoreJobRelevance(JobModel job, UserModel user) {
    double score = 0;

    // Category match (30 points)
    if (user.preferredCategories.contains('All') ||
        user.preferredCategories.contains(job.category)) {
      score += 30;
    }

    // State match (20 points)
    if (user.preferredStates.contains('All India') ||
        user.preferredStates.contains(job.state) ||
        job.state == 'All India') {
      score += 20;
    }

    // Qualification match (25 points)
    final qualScore = _qualificationMatch(job.qualification, user.qualification);
    score += qualScore * 25;

    // Urgency score — jobs expiring soon but not too soon (15 points)
    final daysLeft = job.daysLeft;
    if (daysLeft >= 5 && daysLeft <= 15) {
      score += 15;
    } else if (daysLeft > 15 && daysLeft <= 30) {
      score += 10;
    } else if (daysLeft > 1 && daysLeft < 5) {
      score += 5; // urgent but risky
    }

    // High posts = better opportunities (10 points)
    if (job.totalPosts >= 10000) score += 10;
    else if (job.totalPosts >= 1000) score += 7;
    else if (job.totalPosts >= 100) score += 4;
    else score += 1;

    return score.clamp(0, 100);
  }

  /// Get personalized job recommendations sorted by relevance
  static List<JobModel> getRecommendations(List<JobModel> jobs, UserModel user, {int limit = 20}) {
    final scored = jobs
        .where((j) => !j.isExpired)
        .map((j) => MapEntry(j, scoreJobRelevance(j, user)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  // ─── Smart Search ──────────────────────────────────────────────────────────
  /// Fuzzy + smart search across job fields
  static List<JobModel> smartSearch(List<JobModel> jobs, String query) {
    if (query.trim().isEmpty) return jobs;

    final q = query.toLowerCase().trim();
    final tokens = q.split(RegExp(r'\s+'));

    // Expand common abbreviations
    final expandedTokens = tokens.expand((t) => _expandAbbreviation(t)).toSet();

    final scored = jobs.map((job) {
      double score = 0;
      final searchable = '${job.title} ${job.department} ${job.category} '
          '${job.qualification} ${job.state} ${job.description}'.toLowerCase();

      // Exact phrase match
      if (searchable.contains(q)) score += 100;

      // Individual token matches
      for (final token in expandedTokens) {
        if (token.length < 2) continue;
        if (job.title.toLowerCase().contains(token)) score += 40;
        if (job.department.toLowerCase().contains(token)) score += 30;
        if (job.category.toLowerCase().contains(token)) score += 25;
        if (job.state.toLowerCase().contains(token)) score += 15;
        if (job.qualification.toLowerCase().contains(token)) score += 15;
        if (job.description.toLowerCase().contains(token)) score += 5;
      }

      // Fuzzy match (bigram similarity)
      final titleSim = _bigramSimilarity(job.title.toLowerCase(), q);
      score += titleSim * 30;

      return MapEntry(job, score);
    }).where((e) => e.value > 10).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  // ─── Trend Detection ───────────────────────────────────────────────────────
  /// Detect trending categories based on recent job additions
  static List<String> getTrendingCategories(List<JobModel> recentJobs) {
    final counts = <String, int>{};
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));

    for (final job in recentJobs) {
      if (job.createdAt.isAfter(last7Days)) {
        counts[job.category] = (counts[job.category] ?? 0) + 1;
      }
    }

    return counts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        .map((e) => e.key)
        .take(5)
        .toList();
  }

  // ─── Exam Pattern Recognition ──────────────────────────────────────────────
  /// Extract exam syllabus topics from description
  static List<SyllabusTopic> extractSyllabus(JobModel job) {
    final desc = job.description.toLowerCase();
    final topics = <SyllabusTopic>[];

    final syllabusDefs = {
      'General Awareness': [
        'current affairs', 'general awareness', 'history', 'geography',
        'polity', 'economy', 'science', 'sports', 'awards'
      ],
      'Quantitative Aptitude': [
        'mathematics', 'quantitative aptitude', 'numerical ability',
        'arithmetic', 'algebra', 'number system', 'percentage'
      ],
      'Reasoning': [
        'reasoning', 'logical', 'analytical', 'verbal', 'non-verbal',
        'coding', 'series', 'puzzle', 'syllogism'
      ],
      'English Language': [
        'english', 'grammar', 'comprehension', 'vocabulary', 'synonyms',
        'antonyms', 'fill in the blanks'
      ],
      'General Science': [
        'physics', 'chemistry', 'biology', 'science', 'environment'
      ],
      'Computer Knowledge': [
        'computer', 'ms office', 'internet', 'networking', 'software'
      ],
      'Hindi Language': [
        'hindi', 'व्याकरण', 'हिंदी'
      ],
    };

    for (final entry in syllabusDefs.entries) {
      final matchCount = entry.value.where((kw) => desc.contains(kw)).length;
      if (matchCount > 0) {
        topics.add(SyllabusTopic(
          name: entry.key,
          relevance: matchCount / entry.value.length,
          subtopics: entry.value.where((kw) => desc.contains(kw)).toList(),
        ));
      }
    }

    // Sort by relevance
    topics.sort((a, b) => b.relevance.compareTo(a.relevance));
    return topics;
  }

  // ─── Smart Deadline Prediction ─────────────────────────────────────────────
  /// Predict if job deadline might be extended based on historical patterns
  static bool likelyToExtend(JobModel job) {
    // SSC and Railway jobs historically often extend
    final extendProneCats = ['SSC', 'Railway', 'Banking'];
    return extendProneCats.contains(job.category) && job.totalPosts > 5000;
  }

  // ─── Content Generation ────────────────────────────────────────────────────
  /// Generate a smart job summary for notification
  static String generateJobSummary(JobModel job) {
    final parts = <String>[];

    if (job.totalPosts > 0) parts.add('${_formatNumber(job.totalPosts)} Posts');
    if (job.qualification.isNotEmpty && job.qualification != 'As per notification') {
      parts.add(job.qualification);
    }
    if (job.ageLimit.isNotEmpty && job.ageLimit != 'As per notification') {
      parts.add('Age: ${job.ageLimit}');
    }
    parts.add('Apply by ${_formatDate(job.lastDate)}');

    return parts.join(' • ');
  }

  /// Generate preparation tips for a job
  static List<String> generatePreparationTips(JobModel job) {
    final tips = <String>[];
    final cat = job.category;

    final categoryTips = {
      'SSC': [
        '📚 Focus on Quantitative Aptitude and Reasoning',
        '📰 Read newspaper daily for General Awareness',
        '✍️ Practice previous year papers from SSC official site',
        '⏱️ Work on speed and accuracy — time management is key',
        '💻 Use SSC official study material from ssc.nic.in',
      ],
      'Railway': [
        '🚂 Study Technical subjects based on your trade',
        '🔧 Focus on General Science for RRB exams',
        '📊 Practice arithmetic and basic Mathematics daily',
        '🗺️ Learn Indian Railway history and facts',
        '📱 Download RRB official app for updates',
      ],
      'Banking': [
        '💰 Master Data Interpretation and Quantitative Aptitude',
        '📝 Practice English Grammar and Reading Comprehension',
        '🏦 Study Banking Awareness and Financial awareness',
        '⚡ Improve typing speed for Clerk positions',
        '📈 Follow RBI and IBPS official websites',
      ],
      'UPSC': [
        '📖 Read NCERT books from Class 6-12 thoroughly',
        '🗞️ Read The Hindu newspaper daily',
        '✍️ Practice answer writing for Mains',
        '🗺️ Study Indian Polity by Laxmikant',
        '📋 Make concise notes for quick revision',
      ],
      'Defence': [
        '💪 Focus on Physical fitness — run 5km daily',
        '📚 Study Class 10/12 Maths and Science thoroughly',
        '🎯 Practice shooting accuracy if applicable',
        '🧠 Improve logical reasoning and spatial ability',
        '🏋️ Follow NDA/CDS official fitness standards',
      ],
    };

    tips.addAll(categoryTips[cat] ?? [
      '📚 Study the official notification carefully',
      '✍️ Practice previous year question papers',
      '📅 Make a study schedule and stick to it',
      '💡 Focus on your weak areas daily',
      '🌐 Check official website regularly for updates',
    ]);

    return tips;
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────
  static double _qualificationMatch(String jobQual, String userQual) {
    if (userQual.isEmpty) return 0.5;

    final hierarchy = [
      '8th Pass', '10th Pass', '12th Pass', 'Diploma',
      'Graduation', 'Post Graduation', 'B.Tech/B.E.', 'MBBS'
    ];

    final jobLevel = hierarchy.indexWhere(
        (q) => jobQual.toLowerCase().contains(q.toLowerCase()));
    final userLevel = hierarchy.indexWhere(
        (q) => userQual.toLowerCase().contains(q.toLowerCase()));

    if (jobLevel == -1 || userLevel == -1) return 0.5;
    if (userLevel >= jobLevel) return 1.0; // user is qualified
    if (userLevel == jobLevel - 1) return 0.3; // close but not quite
    return 0.0; // not qualified
  }

  static List<String> _expandAbbreviation(String token) {
    const expansions = {
      'ssc': ['ssc', 'staff selection commission'],
      'rrb': ['rrb', 'railway recruitment board'],
      'upsc': ['upsc', 'union public service'],
      'ibps': ['ibps', 'bank'],
      'ntpc': ['ntpc', 'non technical popular categories'],
      'gd': ['gd', 'general duty', 'constable'],
      'cgl': ['cgl', 'combined graduate level'],
      'chsl': ['chsl', 'combined higher secondary'],
    };
    return expansions[token] ?? [token];
  }

  static double _bigramSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    Set<String> bigrams(String s) =>
        Set.from(List.generate(s.length - 1, (i) => s.substring(i, i + 2)));
    final bigramsA = bigrams(a);
    final bigramsB = bigrams(b);
    if (bigramsA.isEmpty || bigramsB.isEmpty) return 0;
    final intersection = bigramsA.intersection(bigramsB).length;
    return (2 * intersection) / (bigramsA.length + bigramsB.length);
  }

  static String _formatNumber(int n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class SyllabusTopic {
  final String name;
  final double relevance;
  final List<String> subtopics;

  SyllabusTopic({
    required this.name,
    required this.relevance,
    required this.subtopics,
  });
}
