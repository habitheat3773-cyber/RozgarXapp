const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const scraper = require("./scrapers/mega_scraper");
const parser  = require("./parsers/ai_parser");
const notifier = require("./notifiers/fcm_notifier");
const { isDuplicate } = require("./utils/duplicate_checker");
const { analyzeAndScore } = require("./ai/job_scorer");

const db  = admin.firestore();
const msg = admin.messaging();

// ─── SCHEDULED: Auto Fetch Every 3 Hours ──────────────────────────────────────
exports.autoFetchJobs = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .pubsub.schedule("every 3 hours")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    console.log("🚀 RozgarX Auto Fetch Started —", new Date().toISOString());
    const stats = { added: 0, skipped: 0, errors: 0, sources: {} };

    const rawJobs = await scraper.scrapeAllSources();
    console.log(`📦 Total scraped: ${rawJobs.length}`);

    const batch = db.batch();
    let batchCount = 0;

    for (const raw of rawJobs) {
      try {
        const parsed = parser.parseJob(raw);
        if (!parsed) { stats.skipped++; continue; }

        const dup = await isDuplicate(db, parsed.title, parsed.last_date);
        if (dup) { stats.skipped++; continue; }

        const scored = analyzeAndScore(parsed);
        const ref = db.collection("jobs").doc();
        batch.set(ref, {
          ...scored,
          id: ref.id,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          is_featured: false,
          auto_added: true,
          view_count: 0,
          apply_click_count: 0,
        });
        batchCount++;
        stats.added++;
        stats.sources[raw.source_name] = (stats.sources[raw.source_name] || 0) + 1;

        if (batchCount >= 400) {
          await batch.commit();
          batchCount = 0;
        }
      } catch (err) {
        stats.errors++;
        console.error("Parse error:", err.message);
      }
    }

    if (batchCount > 0) await batch.commit();

    // Log run
    await db.collection("logs").add({
      type: "auto_fetch", ...stats,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Done — Added: ${stats.added}, Skipped: ${stats.skipped}, Errors: ${stats.errors}`);
    console.log("📊 Sources:", JSON.stringify(stats.sources));
  });

// ─── TRIGGER: New Job → Push Notification ─────────────────────────────────────
exports.onNewJobAdded = functions.firestore
  .document("jobs/{jobId}")
  .onCreate(async (snap) => {
    const job = { id: snap.id, ...snap.data() };
    await notifier.sendJobNotification(msg, job);
  });

// ─── SCHEDULED: Clean Expired Jobs Daily ──────────────────────────────────────
exports.cleanExpiredJobs = functions
  .runWith({ timeoutSeconds: 120 })
  .pubsub.schedule("every 24 hours")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db.collection("jobs")
      .where("last_date", "<", now)
      .where("auto_added", "==", true)
      .get();

    if (expired.empty) {
      console.log("✅ No expired jobs to clean");
      return;
    }

    const batch = db.batch();
    expired.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    console.log(`🗑️ Deleted ${expired.size} expired jobs`);
    await db.collection("logs").add({
      type: "cleanup",
      deleted: expired.size,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// ─── SCHEDULED: Deadline Reminders Daily at 8am ───────────────────────────────
exports.sendDeadlineReminders = functions
  .runWith({ timeoutSeconds: 120 })
  .pubsub.schedule("0 8 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const now = new Date();
    const in3days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    const in7days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const snap = await db.collection("jobs")
      .where("last_date", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("last_date", "<=", admin.firestore.Timestamp.fromDate(in7days))
      .get();

    let sent = 0;
    for (const doc of snap.docs) {
      const job = doc.data();
      const daysLeft = Math.ceil((job.last_date.toDate() - now) / 86400000);
      if (daysLeft === 1 || daysLeft === 3 || daysLeft === 7) {
        await notifier.sendDeadlineReminder(msg, job, daysLeft);
        sent++;
      }
    }
    console.log(`🔔 Sent ${sent} deadline reminders`);
  });

// ─── HTTP: Admin Stats API ─────────────────────────────────────────────────────
exports.getAdminStats = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }

  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  try {
    const [jobsSnap, usersSnap, logsSnap] = await Promise.all([
      db.collection("jobs").get(),
      db.collection("users").get(),
      db.collection("logs").orderBy("timestamp", "desc").limit(20).get(),
    ]);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayJobs = jobsSnap.docs.filter(d => {
      const ts = d.data().created_at?.toDate?.();
      return ts && ts >= today;
    });

    // Category breakdown
    const catBreakdown = {};
    jobsSnap.docs.forEach(d => {
      const cat = d.data().category || "Other";
      catBreakdown[cat] = (catBreakdown[cat] || 0) + 1;
    });

    res.json({
      totalJobs: jobsSnap.size,
      totalUsers: usersSnap.size,
      jobsToday: todayJobs.length,
      categoryBreakdown: catBreakdown,
      recentLogs: logsSnap.docs.map(d => ({ id: d.id, ...d.data() })),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── HTTP: Track Job Analytics ─────────────────────────────────────────────────
exports.trackJobEvent = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method !== "POST") return res.status(405).end();

  const { jobId, event } = req.body;
  if (!jobId || !event) return res.status(400).json({ error: "Missing fields" });

  const field = event === "view" ? "view_count" : "apply_click_count";
  await db.collection("jobs").doc(jobId).update({
    [field]: admin.firestore.FieldValue.increment(1),
  });
  res.json({ success: true });
});
