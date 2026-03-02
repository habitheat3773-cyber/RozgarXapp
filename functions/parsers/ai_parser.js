const admin = require("firebase-admin");

/**
 * RozgarX AI Parser v2.0
 * Rule-based intelligence that extracts structured data from raw scraped text
 * No external API — 100% own logic
 */
function parseJob(raw) {
  const text = raw.raw_text || "";
  if (!text || text.trim().length < 15) return null;

  const lastDate = extractLastDate(text);
  if (!lastDate) return null; // skip jobs without parseable dates

  return {
    title:           extractTitle(text, raw.source_department),
    department:      raw.source_department,
    category:        detectCategory(text, raw.source_category),
    state:           detectState(text),
    qualification:   detectQualification(text),
    age_limit:       extractAgeLimit(text),
    total_posts:     extractPosts(text),
    last_date:       lastDate,
    apply_link:      raw.raw_link || raw.source_url,
    notification_link: raw.raw_link,
    description:     text.substring(0, 600),
    source_url:      raw.source_url,
    application_fee: extractFee(text),
    salary_range:    extractSalary(text),
    pay_scale:       extractPayScale(text),
    tags:            extractTags(text),
    extra_data: {
      scraped_from: raw.source_name,
      raw_length: text.length,
    },
  };
}

// ─── TITLE EXTRACTION ─────────────────────────────────────────────────────────
function extractTitle(text, dept) {
  const patterns = [
    /(?:^|\n)([A-Z][^\n\.]{15,80}(?:Recruitment|Vacancy|Post|Bharti|Notification)[^\n\.]{0,40})/,
    /([A-Z][^\n\.]{15,80}?\s+(?:\d{4}|Recruitment|Vacancy|Posts?))[,\.\n]/,
    /(?:Recruitment|Vacancy)\s+(?:of|for|in)\s+([^\n\.]{10,80})/i,
    /([^\n\.]{15,80}?)\s+(?:Recruitment|Vacancy)\s+(?:20\d{2})/i,
  ];

  for (const p of patterns) {
    const m = text.match(p);
    if (m && m[1]) return clean(m[1].trim());
  }

  // Fallback: first sentence
  const first = text.split(/[\n\.]/)[0].trim();
  return first.length >= 15
    ? clean(first.substring(0, 100))
    : `${dept} Recruitment ${new Date().getFullYear()}`;
}

// ─── CATEGORY DETECTION ───────────────────────────────────────────────────────
function detectCategory(text, fallback) {
  const lower = text.toLowerCase();
  const MAP = [
    { words: ["ssc", "staff selection commission", "combined graduate", "cgl", "chsl", "mts", "stenographer"], cat: "SSC" },
    { words: ["railway", "rrb", "rrbs", "rpf", "rrc", "ntpc", "group d", "loco pilot", "alp"], cat: "Railway" },
    { words: ["bank", "ibps", "sbi po", "rbi", "nabard", "sidbi", "clerk po so"], cat: "Banking" },
    { words: ["army", "navy", "air force", "crpf", "cisf", "bsf", "itbp", "ssb", "nda", "agniveer", "defence", "military", "paramilitary"], cat: "Defence" },
    { words: ["teacher", "tet", "ctet", "kvs", "nvs", "school", "principal", "headmaster", "tgt", "pgt", "lecturer"], cat: "Teaching" },
    { words: ["police", "constable", "sub-inspector", "si ", "ips", "traffic"], cat: "Police" },
    { words: ["upsc", "ias", "ips", "ifs", "civil services", "capf"], cat: "UPSC" },
    { words: ["psc", "state public service", "hpsc", "bpsc", "mpsc", "rpsc", "uppsc", "opsc", "tnpsc", "kpsc", "wbpsc", "gpsc"], cat: "State PSC" },
    { words: ["b.tech", "b.e.", "engineering", "junior engineer", "je ", "ae ", "assistant engineer", "iti", "diploma", "polytechnic", "drdo", "isro", "hal", "bel"], cat: "Engineering" },
    { words: ["doctor", "mbbs", "nurse", "medical", "health", "nhm", "aiims", "pharmacist", "lab technician", "bds", "ayush", "anm", "gnm"], cat: "Medical" },
    { words: ["high court", "district court", "judiciary", "clerk grade", "law", "stenographer court"], cat: "Legal" },
  ];
  for (const { words, cat } of MAP) {
    if (words.some(w => lower.includes(w))) return cat;
  }
  return fallback || "Other";
}

// ─── STATE DETECTION ──────────────────────────────────────────────────────────
function detectState(text) {
  const lower = text.toLowerCase();
  const STATES = [
    { words: ["uttar pradesh", "u.p.", " up ", "lucknow", "bpsc up", "uppsc"], state: "Uttar Pradesh" },
    { words: ["bihar", "bpsc", "patna"], state: "Bihar" },
    { words: ["rajasthan", "rpsc", "jaipur"], state: "Rajasthan" },
    { words: ["madhya pradesh", "m.p.", "mppsc", "bhopal"], state: "Madhya Pradesh" },
    { words: ["maharashtra", "mpsc", "mumbai", "pune", "nagpur"], state: "Maharashtra" },
    { words: ["delhi", "dsssb", "gnct", "ndmc"], state: "Delhi" },
    { words: ["gujarat", "gpsc", "ahmedabad"], state: "Gujarat" },
    { words: ["west bengal", "wbpsc", "kolkata"], state: "West Bengal" },
    { words: ["andhra pradesh", "appsc", "amaravati"], state: "Andhra Pradesh" },
    { words: ["telangana", "tspsc", "hyderabad"], state: "Telangana" },
    { words: ["tamil nadu", "tnpsc", "chennai"], state: "Tamil Nadu" },
    { words: ["karnataka", "kpsc", "bengaluru", "bangalore"], state: "Karnataka" },
    { words: ["haryana", "hpsc", "chandigarh", "hsssc"], state: "Haryana" },
    { words: ["punjab", "ppsc", "punjab state"], state: "Punjab" },
    { words: ["uttarakhand", "ukpsc", "dehradun", "uk govt"], state: "Uttarakhand" },
    { words: ["himachal pradesh", "hppsc", "shimla"], state: "Himachal Pradesh" },
    { words: ["jharkhand", "jpsc", "ranchi"], state: "Jharkhand" },
    { words: ["odisha", "opsc", "bhubaneswar"], state: "Odisha" },
    { words: ["assam", "apsc", "guwahati"], state: "Assam" },
    { words: ["kerala", "kerala psc", "thiruvananthapuram"], state: "Kerala" },
    { words: ["goa", "goa state"], state: "Goa" },
    { words: ["chhattisgarh", "cgpsc", "raipur"], state: "Chhattisgarh" },
  ];
  for (const { words, state } of STATES) {
    if (words.some(w => lower.includes(w))) return state;
  }
  return "All India";
}

// ─── QUALIFICATION DETECTION ──────────────────────────────────────────────────
function detectQualification(text) {
  const lower = text.toLowerCase();
  const QUALS = [
    { words: ["mbbs", "medical graduate"], qual: "MBBS" },
    { words: ["b.tech", "b.e.", "engineering degree", "be/b.tech", "b.tech/be"], qual: "B.Tech/B.E." },
    { words: ["llb", "law graduate", "advocate"], qual: "LLB" },
    { words: ["m.sc", "m.a.", "mba", "m.com", "post graduation", "post-graduation", "masters", "m.tech"], qual: "Post Graduation" },
    { words: ["b.sc", "b.a.", "b.com", "graduation", "graduate", "degree holder", "any degree", "bachelor"], qual: "Graduation" },
    { words: ["diploma", "polytechnic", "iti ", "i.t.i.", "trade apprentice"], qual: "Diploma/ITI" },
    { words: ["12th", "class xii", "intermediate", "higher secondary", "10+2", "hs pass"], qual: "12th Pass" },
    { words: ["10th", "class x", "matriculation", "matric", "ssc pass", "secondary"], qual: "10th Pass" },
    { words: ["8th", "class viii", "middle pass"], qual: "8th Pass" },
  ];
  for (const { words, qual } of QUALS) {
    if (words.some(w => lower.includes(w))) return qual;
  }
  return "As per notification";
}

// ─── AGE LIMIT ────────────────────────────────────────────────────────────────
function extractAgeLimit(text) {
  const patterns = [
    /age\s*(?:limit|criteria|bar)?\s*[:\-–]\s*(\d{1,2})\s*(?:to|–|-)\s*(\d{1,2})\s*years?/i,
    /(\d{1,2})\s*(?:to|–|-)\s*(\d{1,2})\s*years?\s*(?:of\s+)?(?:age|old)/i,
    /minimum\s*age\s*[:\-]?\s*(\d{1,2})\s*years?.*?maximum\s*age\s*[:\-]?\s*(\d{1,2})/i,
    /age\s*[:\-]\s*(\d{1,2})\s*[-–]\s*(\d{1,2})/i,
    /(\d{1,2})\s*वर्ष\s*से\s*(\d{1,2})\s*वर्ष/,
  ];
  for (const p of patterns) {
    const m = text.match(p);
    if (m && m[1] && m[2]) return `${m[1]}-${m[2]} Years`;
    if (m && m[1]) return `${m[1]}+ Years`;
  }
  return "As per notification";
}

// ─── TOTAL POSTS ──────────────────────────────────────────────────────────────
function extractPosts(text) {
  const patterns = [
    /(\d{1,6})\s*(?:posts?|vacancies|seats?|positions?)/i,
    /(?:total|no\.?\s*of|number\s*of)\s*(?:posts?|vacancies|seats?)\s*[:\-]?\s*(\d{1,6})/i,
    /vacancies?\s*[:\-]?\s*(\d{1,6})/i,
    /(\d{1,6})\s*(?:रिक्त\s*पद|पद)/,
  ];
  for (const p of patterns) {
    const m = text.match(p);
    if (m) {
      const n = parseInt(m[1] || m[2] || "0");
      if (n > 0 && n < 500000) return n;
    }
  }
  return 0;
}

// ─── LAST DATE ────────────────────────────────────────────────────────────────
function extractLastDate(text) {
  const patterns = [
    /(?:last\s+date|closing\s+date|end\s+date|apply\s+(?:before|by)|submission\s+of\s+application)\s*[:\-]?\s*(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})/i,
    /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\s*(?:\(last\s+date\)|is\s+last\s+date)/i,
    /(\d{1,2})\s+(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})/i,
    /(\d{1,2})\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{4})/i,
    /(?:last\s+date)[^\d]*(\d{1,2})[^\d]{1,3}(\d{1,2})[^\d]{1,3}(\d{2,4})/i,
  ];

  const MONTHS = { january:0,february:1,march:2,april:3,may:4,june:5,july:6,august:7,september:8,october:9,november:10,december:11,
    jan:0,feb:1,mar:2,apr:3,may2:4,jun:5,jul:6,aug:7,sep:8,oct:9,nov:10,dec:11 };

  for (const p of patterns) {
    const m = text.match(p);
    if (!m) continue;
    try {
      let date;
      if (isNaN(parseInt(m[2]))) {
        // Month name format: "15 March 2026"
        const monthKey = m[2].toLowerCase();
        const month = MONTHS[monthKey] ?? MONTHS[monthKey.substring(0,3)];
        if (month === undefined) continue;
        const year = parseInt(m[3] || m[2]);
        date = new Date(year, month, parseInt(m[1]));
      } else {
        const day   = parseInt(m[1]);
        const month = parseInt(m[2]) - 1;
        let   year  = parseInt(m[3]);
        if (year < 100) year += 2000;
        date = new Date(year, month, day);
      }
      if (!isNaN(date.getTime()) && date > new Date()) {
        return admin.firestore.Timestamp.fromDate(date);
      }
    } catch (_) {}
  }

  // Default: 30 days from now
  const d = new Date();
  d.setDate(d.getDate() + 30);
  return admin.firestore.Timestamp.fromDate(d);
}

// ─── APPLICATION FEE ──────────────────────────────────────────────────────────
function extractFee(text) {
  const m = text.match(/(?:application\s+fee|fee)[^₹₹Rs.]*(?:₹|Rs\.?|INR)\s*(\d+)/i)
         || text.match(/(?:₹|Rs\.?)\s*(\d{2,4})\s*(?:only|\/[-]?)[^\d]/);
  if (m) return `₹${m[1]}`;
  if (/no\s+fee|fee\s+exempt|nil\s+fee|free/i.test(text)) return "No Fee";
  return null;
}

// ─── SALARY ───────────────────────────────────────────────────────────────────
function extractSalary(text) {
  const m = text.match(/(?:salary|pay|emoluments)[^₹Rs.0-9]*(?:₹|Rs\.?)?\s*(\d[\d,]+)\s*[-–to]+\s*(?:₹|Rs\.?)?\s*(\d[\d,]+)/i);
  if (m) return `₹${m[1].replace(/,/g,"")} - ₹${m[2].replace(/,/g,"")} per month`;
  return null;
}

function extractPayScale(text) {
  const m = text.match(/pay\s*(?:scale|band|matrix)[^0-9]*(?:₹|Rs\.?)?\s*(\d[\d,]+)\s*[-–to]+\s*(?:₹|Rs\.?)?\s*(\d[\d,]+)/i)
         || text.match(/level\s*(\d{1,2})/i);
  if (m && m[2]) return `Pay Scale: ₹${m[1]} - ₹${m[2]}`;
  if (m && m[1]) return `Pay Matrix Level ${m[1]}`;
  return null;
}

function extractTags(text) {
  const lower = text.toLowerCase();
  const tags = [];
  if (/fresh|fresher|experience\s+not\s+required/.test(lower)) tags.push("fresher");
  if (/work\s+from\s+home|remote|wfh/.test(lower)) tags.push("remote");
  if (/walk.in|walk\s+in/.test(lower)) tags.push("walk-in");
  if (/urgent|immediate/.test(lower)) tags.push("urgent");
  if (/women|female|lady/.test(lower)) tags.push("women-preferred");
  if (/ex.servicemen|exsm/.test(lower)) tags.push("ex-servicemen");
  if (/pwd|divyang|differently\s+abled/.test(lower)) tags.push("pwd");
  return tags;
}

function clean(text) {
  return text.replace(/\s+/g, " ").replace(/[^\w\s\-\.\/,()₹]/g, "").trim().substring(0, 120);
}

module.exports = { parseJob };
