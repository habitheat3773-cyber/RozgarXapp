async function isDuplicate(db, title, lastDate) {
  if (!title) return false;
  const norm = title.toLowerCase().replace(/[^a-z0-9\s]/g,"").replace(/\s+/g," ").trim();
  const prefix = norm.substring(0, 35);
  try {
    const snap = await db.collection("jobs")
      .where("title", ">=", prefix)
      .where("title", "<=", prefix + "\uf8ff")
      .limit(5).get();
    for (const doc of snap.docs) {
      const existing = (doc.data().title || "").toLowerCase().replace(/[^a-z0-9\s]/g,"").trim();
      if (jaccard(norm, existing) > 0.75) return true;
    }
  } catch (_) {}
  return false;
}

function jaccard(a, b) {
  const sa = new Set(a.split(" ")), sb = new Set(b.split(" "));
  const inter = [...sa].filter(x => sb.has(x)).length;
  const union = new Set([...sa,...sb]).size;
  return union === 0 ? 0 : inter / union;
}

module.exports = { isDuplicate };
