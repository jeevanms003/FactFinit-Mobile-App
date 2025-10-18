# FactFinit - System Overview

## What It Does

FactFinit verifies financial claims in YouTube videos using AI-powered fact-checking. Users submit video URLs, the app extracts transcripts, detects financial content, identifies claims, and verifies them against real financial news data.

---

## Architecture
```
Mobile App (Flutter)
      ↓ REST API
Backend (Node.js/Express)
      ↓
   MongoDB + Gemini AI + RAG API
```

**Components:**
- **Frontend:** Flutter mobile app (iOS/Android)
- **Backend:** Node.js + Express + TypeScript
- **Database:** MongoDB with 7-day TTL caching
- **AI Services:** Google Gemini + RAG (FastAPI + ChromaDB)

---

## Tech Stack

### Backend
- Express.js 5.1.0 + TypeScript
- MongoDB + Mongoose ODM
- JWT + bcrypt authentication
- Google Gemini AI (gemini-2.5-flash-lite)
- youtube-transcript-plus

### Frontend
- Flutter 3.0+ SDK
- Provider (state management)
- Material Design theming
- HTTP client for API calls

### RAG API
- FastAPI + Python
- ChromaDB (vector database)
- SentenceTransformer (all-MiniLM-L6-v2)
- Pandas for CSV processing

---

## Key Features

### Authentication
- JWT token-based (1-hour expiry)
- bcrypt password hashing
- Protected routes with middleware
- User-scoped data access

### Video Verification
- YouTube URL support (7 formats)
- Multi-language transcripts (EN, HI, TA, BN, MR)
- Automatic platform detection
- Financial content detection
- Up to 3 claims fact-checked per video
- 100-200 word explanations per claim
- Credible sources with URLs

### Caching
- MongoDB caching per user + video URL
- 7-day automatic expiration (TTL index)
- Instant results for cached videos
- Reduces API costs significantly

### History
- Paginated search history (10/page)
- Full fact-check details
- Clickable source links
- Copy transcript to clipboard

### Mobile Features
- Light/Dark theme toggle
- URL sharing from other apps (Android intents)
- Responsive design (mobile + tablet)
- Smooth animations and loading states

---

## Data Flow

### Verification Process
```
1. User submits video URL
2. Validate URL format (YouTube/Instagram)
3. Check MongoDB cache (user + URL)
4. Extract video ID
5. Fetch multi-language transcripts
6. Parallel fact-checking:
   ├─ Gemini: Normalize + detect financial + verify claims
   └─ RAG: Query financial news database
7. Merge results (prioritize RAG for financial)
8. Save to MongoDB (7-day TTL)
9. Return results to frontend
```

### AI Fact-Checking
```
Gemini AI:
- Translates to English
- Normalizes grammar
- Detects financial content
- Identifies 3 major claims
- Verifies accuracy
- Provides sources

RAG API:
- Encodes query as vector (384-dim)
- Searches financial news database
- Returns top 5 relevant passages
- Sorted by date (newest first)
- "OUT OF CONTEXT" if irrelevant
```

---

## Database Schemas

### Users
```javascript
{
  email: String (unique),
  password: String (bcrypt hashed),
  createdAt: Date
}
```

### Transcripts
```javascript
{
  videoURL: String,
  platform: String,
  transcript: Object (multi-language),
  normalizedTranscript: String,
  isFinancial: Boolean,
  factCheck: {
    claims: [{
      claim: String,
      isAccurate: Boolean,
      explanation: String
    }],
    sources: [{
      title: String,
      url: String,
      snippet: String
    }]
  },
  user: ObjectId,
  createdAt: Date
  // Expires after 7 days
}
```

---

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Get JWT token

### Verification
- `POST /api/verify` - Verify video (requires JWT)
- `GET /api/verify?page=1&limit=10` - Get verified videos

### History
- `GET /api/history?page=1&limit=10` - Get search history

### RAG API
- `POST /query` - Query financial news database

---

## Security

- Passwords hashed with bcrypt (10 rounds)
- JWT tokens expire in 1 hour
- Token validation on protected routes
- User-scoped data (no cross-user access)
- Input validation (email, URL formats)
- CORS enabled (configurable)

---

## Supported Platforms

### YouTube ✅
- `youtube.com/watch?v=`
- `youtu.be/`
- `youtube.com/shorts/`
- `youtube.com/embed/`
- `youtube.com/live/`

### Instagram ⚠️
- Detection works
- Transcript extraction NOT implemented

---

## Languages Supported

1. **English (en)** - Primary
2. **Hindi (hi)**
3. **Tamil (ta)**
4. **Bengali (bn)**
5. **Marathi (mr)**

All translated to English for fact-checking.

---

## What It Can Do

✅ Verify YouTube and Instagram financial claims  
✅ Multi-language transcript support  
✅ AI-powered fact-checking  
✅ Detailed explanations with sources  
✅ 7-day result caching  
✅ User authentication  
✅ Search history with pagination  
✅ Light/Dark themes  
✅ Share URLs from other apps  

## What It Cannot Do

❌ Non-financial content verification  
❌ Videos without transcripts  
❌ Transcripts > 5000 characters (truncated)  
❌ Offline mode  
❌ Persistent login (tokens in memory)  

---

## Deployment

### Backend
- Node.js 20.x on Render/Heroku/Railway
- Port 5000, listens on 0.0.0.0
- Requires MongoDB Atlas connection
- Environment variables: PORT, MONGODB_URI, JWT_SECRET, GEMINI_API_KEY

### Frontend
- Flutter APK (Android)
- Flutter IPA (iOS)
- Min SDK: Android 21

### RAG API
- Python FastAPI on port 8001
- ChromaDB persistent storage
- Requires: CSV dataset, Gemini API key

---

## Performance

- **Cache Hit:** Instant response (<100ms)
- **Cache Miss:** 3-5 seconds (AI processing)
- **RAG Query:** <1 second (vector search)
- **Max Transcript:** 5000 characters
- **Pagination:** 10 items/page
- **Concurrent Users:** Supported (user-scoped)

---

## Error Handling

- Graceful fallback (Gemini ↔ RAG)
- User-friendly error messages
- Retry buttons on failures
- Logged to `fact_checker_errors.log`
- Empty fact-check on total failure

---

## Key Design Decisions

**JWT in Memory:** Security + simplicity, auto-logout on close  
**7-Day Cache:** Balance freshness vs performance  
**Dual AI:** RAG for news, Gemini for reasoning  
**MongoDB:** Flexible schema, TTL indexes  
**Flutter:** Single codebase for iOS + Android  

---

## System Limitations

- Gemini API rate limits
- 5000 char transcript limit
- 1-hour token expiry
- Financial content only
- No real-time updates
- No collaboration features

---

## Future Enhancements

- Instagram transcript extraction
- Persistent login (refresh tokens)
- Real-time updates (WebSocket)
- Export history as PDF
- Push notifications
- Web version (PWA)
- Social sharing features
- User ratings for accuracy
