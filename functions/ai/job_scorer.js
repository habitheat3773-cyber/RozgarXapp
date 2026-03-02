// job_scorer.js — adds AI scoring to each job
function analyzeAndScore(job) {
  let priority = 0;
  if (job.total_posts >= 10000) priority += 30;
  else if (job.total_posts >= 1000) priority += 20;
  else if (job.total_posts >= 100) priority += 10;

  const highCats = ["SSC","Railway","Banking","UPSC","Defence"];
  if (highCats.includes(job.category)) priority += 20;

  const daysLeft = job.last_date
    ? Math.ceil((job.last_date.toDate() - new Date()) / 86400000)
    : 30;
  if (daysLeft >= 7 && daysLeft <= 21) priority += 20;
  else if (daysLeft >= 3) priority += 10;

  if (job.state === "All India") priority += 10;

  return { ...job, ai_priority: Math.min(priority, 100) };
}

module.exports = { analyzeAndScore };
