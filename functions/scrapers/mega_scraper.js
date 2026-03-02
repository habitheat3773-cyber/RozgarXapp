const fetch = require("node-fetch");
const cheerio = require("cheerio");

// 12 Official Government Job Sources (Free, No API)
const SOURCES = [
  { name: "SSC",     url: "https://ssc.nic.in/portal/latestnotice",              category: "SSC",       dept: "Staff Selection Commission" },
  { name: "UPSC",    url: "https://upsc.gov.in/recruitments/active-recruitment-notifications", category: "UPSC",  dept: "Union Public Service Commission" },
  { name: "NHM",     url: "https://nhm.gov.in/index4.php?lang=1&level=0&linkid=103&lid=1",    category: "Medical", dept: "National Health Mission" },
  { name: "DSSSB",   url: "https://dsssb.delhi.gov.in/wps/portal/dsssb/home",   category: "State PSC", dept: "DSSSB Delhi" },
  { name: "ESIC",    url: "https://www.esic.gov.in/RecruitmentNotices",          category: "Medical",   dept: "ESIC" },
  { name: "IBPS",    url: "https://www.ibps.in/",                                category: "Banking",   dept: "IBPS" },
  { name: "SBI",     url: "https://sbi.co.in/web/careers",                      category: "Banking",   dept: "State Bank of India" },
  { name: "HAL",     url: "https://hal-india.co.in/Careers",                    category: "Engineering", dept: "Hindustan Aeronautics Limited" },
  { name: "DRDO",    url: "https://www.drdo.gov.in/careers",                    category: "Engineering", dept: "DRDO" },
  { name: "SAIL",    url: "https://www.sail.co.in/careers",                     category: "Engineering", dept: "Steel Authority of India" },
  { name: "BSNL",    url: "https://bsnl.co.in/opencms/bsnl/BSNL/about_us/company/vacancies.html", category: "Engineering", dept: "BSNL" },
  { name: "AIIMS",   url: "https://www.aiims.edu/index.php/en/upcoming-examinations", category: "Medical", dept: "AIIMS" },
];

async function scrapeAllSources() {
  const allJobs = [];
  const promises = SOURCES.map(s => scrapeSource(s).catch(err => {
    console.error(`❌ ${s.name}: ${err.message}`);
    return [];
  }));
  const results = await Promise.allSettled(promises);
  results.forEach(r => {
    if (r.status === "fulfilled") allJobs.push(...r.value);
  });
  return allJobs;
}

async function scrapeSource(source) {
  const html = await fetchHtml(source.url);
  return extractJobs(html, source);
}

async function fetchHtml(url) {
  const res = await fetch(url, {
    timeout: 12000,
    headers: {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
      "Accept-Encoding": "gzip, deflate, br",
      "Connection": "keep-alive",
    },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return await res.text();
}

function extractJobs(html, source) {
  const $ = cheerio.load(html);
  const jobs = [];

  // Strategy 1: Table rows
  $("table tr").each((i, el) => {
    if (i === 0) return; // skip header
    const text = $(el).text().replace(/\s+/g, " ").trim();
    const link = $(el).find("a[href]").first().attr("href") || "";
    if (text.length > 25 && isJobRelated(text)) {
      jobs.push(buildRaw(text, link, source));
    }
  });

  // Strategy 2: List items
  if (jobs.length === 0) {
    $("li, .item, .notice-item, .recruitment-item").each((i, el) => {
      const text = $(el).text().replace(/\s+/g, " ").trim();
      const link = $(el).find("a").attr("href") || $(el).closest("a").attr("href") || "";
      if (text.length > 25 && isJobRelated(text)) {
        jobs.push(buildRaw(text, link, source));
      }
    });
  }

  // Strategy 3: All anchor tags as fallback
  if (jobs.length === 0) {
    $("a").each((i, el) => {
      const text = $(el).text().trim();
      const link = $(el).attr("href") || "";
      if (text.length > 25 && text.length < 300 && isJobRelated(text)) {
        jobs.push(buildRaw(text, link, source));
      }
    });
  }

  // Deduplicate within source
  const seen = new Set();
  return jobs.filter(j => {
    const key = j.raw_text.substring(0, 50);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  }).slice(0, 25);
}

function buildRaw(text, link, source) {
  return {
    raw_text: text.substring(0, 800),
    raw_link: normalizeUrl(link, source.url),
    source_category: source.category,
    source_department: source.dept,
    source_url: source.url,
    source_name: source.name,
  };
}

function isJobRelated(text) {
  const lower = text.toLowerCase();
  const keywords = [
    "recruitment", "vacancy", "post", "apply", "application", "notification",
    "selection", "examination", "exam", "walkin", "walk-in", "interview",
    "apprentice", "constable", "engineer", "teacher", "officer", "clerk",
    "technician", "driver", "helper", "supervisor", "manager", "director",
    "pharmacist", "nurse", "doctor", "staff", "assistant", "inspector",
    "bharti", "naukri", "jobs", "opening", "position", "hiring",
    "भर्ती", "रिक्ति", "अधिसूचना", "आवेदन",
  ];
  return keywords.some(k => lower.includes(k));
}

function normalizeUrl(link, base) {
  if (!link || link === "#" || link.startsWith("javascript")) return base;
  if (link.startsWith("http")) return link;
  if (link.startsWith("//")) return "https:" + link;
  if (link.startsWith("/")) {
    const u = new URL(base);
    return `${u.protocol}//${u.host}${link}`;
  }
  return new URL(link, base).href;
}

module.exports = { scrapeAllSources };
