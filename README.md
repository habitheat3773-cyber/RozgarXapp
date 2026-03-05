# RozgarX V3 🇮🇳
> Sarkari Naukri, Ek Click Mein

AI-powered government job alert app for India. Built with Flutter + Firebase.

---

## 📱 Features
- Live government job listings from Firestore
- Category filters: SSC, Railway, Banking, UPSC, Defence, Teaching, Police & more
- Job detail with timeline, eligibility, and apply link
- Save jobs offline with bookmarks
- Push notifications via Firebase Cloud Messaging
- Google Sign-In
- Search jobs
- Auto APK build via GitHub Actions

---

## 🚀 GitHub Actions Setup

The app builds automatically when you push to `main`. You need **5 secrets**:

Go to: **GitHub Repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value |
|---|---|
| `GOOGLE_SERVICES_JSON` | Contents of your `google-services.json` file |
| `FIREBASE_OPTIONS_DART` | Contents of your `firebase_options.dart` file |
| `KEYSTORE_BASE64` | Base64 encoded keystore (see below) |
| `KEY_STORE_PASSWORD` | Your keystore password |
| `KEY_PASSWORD` | Your key password |
| `KEY_ALIAS` | Your key alias (e.g. `rozgarx`) |

### Generate Keystore (run in Termux)
```bash
keytool -genkey -v -keystore rozgarx-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rozgarx
base64 -w 0 rozgarx-release.jks
```
Copy the entire base64 output as `KEYSTORE_BASE64`.

---

## 📂 Project Structure
```
flutter_app/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart        ← injected by CI
│   ├── core/
│   │   ├── constants/
│   │   ├── router/
│   │   ├── services/
│   │   └── theme/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   │   ├── home/
│   │   ├── search/
│   │   ├── saved/
│   │   ├── profile/
│   │   └── splash/
│   └── widgets/
└── android/
```

---

## 🔥 Firestore Data Structure

Collection: `jobs`
```json
{
  "title": "SSC CGL 2024",
  "department": "Staff Selection Commission",
  "category": "SSC",
  "state": "All India",
  "total_posts": 17727,
  "salary_range": "₹25,500 - ₹1,51,100",
  "qualification": "Any Graduate",
  "age_limit": "18-32 years",
  "application_fee": "₹100 (Gen), Free (SC/ST/Women)",
  "apply_link": "https://ssc.nic.in",
  "last_date": "2024-12-31T00:00:00Z",
  "exam_date": "2025-02-15T00:00:00Z",
  "is_featured": true,
  "tags": ["ssc", "central", "graduate"],
  "created_at": "2024-11-01T00:00:00Z"
}
```

---

## ✅ Build Status
Push to `main` → GitHub Actions → APK available under Actions → Artifacts
