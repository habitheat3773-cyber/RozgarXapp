const admin = require("firebase-admin");

async function sendJobNotification(messaging, job) {
  const catTopic   = `cat_${(job.category || "other").toLowerCase().replace(/\s+/g, "_").replace(/\//g,"_")}`;
  const stateTopic = `state_${(job.state || "all_india").toLowerCase().replace(/\s+/g, "_")}`;
  const isAllIndia = job.state === "All India";

  const notification = {
    title: `🚨 ${job.title}`.substring(0, 65),
    body: `${job.total_posts > 0 ? job.total_posts + " Posts • " : ""}Apply by ${formatDate(job.last_date?.toDate?.())}`,
  };

  const data = {
    job_id:   job.id || "",
    category: job.category || "",
    type:     "new_job",
    click_action: "FLUTTER_NOTIFICATION_CLICK",
  };

  const topics = ["all_jobs", catTopic];
  if (!isAllIndia) topics.push(stateTopic);

  await Promise.allSettled(
    topics.map(topic =>
      messaging.sendToTopic(topic, {
        notification,
        data,
        android: {
          priority: "high",
          notification: {
            channelId: "rozgarx_jobs",
            color: "#1E3A8A",
            tag: job.id,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: { aps: { badge: 1, sound: "default" } },
        },
      })
    )
  );
  console.log(`📱 Notification sent for: ${job.title}`);
}

async function sendDeadlineReminder(messaging, job, daysLeft) {
  await messaging.sendToTopic("all_jobs", {
    notification: {
      title: `⏰ ${daysLeft} Day${daysLeft > 1 ? "s" : ""} Left to Apply!`,
      body: `${job.title} — Don't miss out!`,
    },
    data: { job_id: job.id || "", type: "deadline_reminder" },
    android: { priority: "high", notification: { channelId: "rozgarx_deadlines", color: "#F97316" } },
  });
}

function formatDate(date) {
  if (!date) return "Soon";
  const m = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `${date.getDate()} ${m[date.getMonth()]}`;
}

module.exports = { sendJobNotification, sendDeadlineReminder };
