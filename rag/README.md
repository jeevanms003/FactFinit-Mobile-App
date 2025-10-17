# FactFinit Backend

## Installation
```bash
npm install
```

## Environment Setup

Create `.env` file:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/factfinit
JWT_SECRET=your-secure-jwt-secret
GEMINI_API_KEY=your-gemini-api-key
RAG_API_URL=http://localhost:8001/query
```

## Run
```bash
# Development
npm run dev

# Production
npm run build
npm start
```

## API Endpoints

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "token": "eyJhbGc..."
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGc..."
}
```

### Video Verification

#### Verify Video
```http
POST /api/verify
Authorization: Bearer <token>
Content-Type: application/json

{
  "videoURL": "https://www.youtube.com/watch?v=VIDEO_ID",
  "platform": "YouTube",
  "language": "en"
}
```

**Response:**
```json
{
  "message": "Transcript processed successfully",
  "data": {
    "videoURL": "https://www.youtube.com/watch?v=VIDEO_ID",
    "platform": "YouTube",
    "transcript": { "en": [...] },
    "normalizedTranscript": "The video discusses...",
    "isFinancial": true,
    "factCheck": {
      "claims": [
        {
          "claim": "Gold was Rs 3000 in 2015",
          "isAccurate": false,
          "explanation": "Average gold price in 2015 was Rs 26,400 per 10g..."
        }
      ],
      "sources": [
        {
          "title": "Gold Rate Trends",
          "url": "https://example.com",
          "snippet": "Historical data..."
        }
      ]
    }
  }
}
```

#### Get All Verified Videos
```http
GET /api/verify?page=1&limit=10
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Fact-checked videos retrieved successfully",
  "data": {
    "transcripts": [...],
    "pagination": {
      "total": 25,
      "page": 1,
      "limit": 10,
      "totalPages": 3
    }
  }
}
```

### History

#### Get Search History
```http
GET /api/history?page=1&limit=10
Authorization: Bearer <token>
```

**Response:** Same format as `/api/verify` GET

## Database Models

### User
```typescript
{
  _id: ObjectId,
  email: string,
  password: string,  // bcrypt hashed
  createdAt: Date,
  updatedAt: Date
}
```

### Transcript
```typescript
{
  videoURL: string,
  platform: "YouTube" | "Instagram",
  transcript: Record<string, TranscriptSegment[]>,
  normalizedTranscript: string,
  isFinancial: boolean,
  factCheck: {
    claims: Array<{
      claim: string,
      isAccurate: boolean,
      explanation: string
    }>,
    sources: Array<{
      title: string,
      url: string,
      snippet: string
    }>
  },
  user: ObjectId,
  createdAt: Date
}
```

## Supported Platforms

- YouTube (`youtube.com`, `youtu.be`)
- Instagram (`instagram.com`) - extraction not implemented

## Supported Languages

- English (en)
- Hindi (hi)
- Tamil (ta)
- Bengali (bn)
- Marathi (mr)

## Services

### Fact Checker (`src/services/factChecker.ts`)

**Gemini AI:**
- Normalizes transcripts to English
- Detects financial content
- Identifies and verifies claims
- Provides 100-200 word explanations

**RAG API:**
- Retrieves relevant financial news
- Provides real-time fact verification
- Returns credible sources

**Merge Logic:**
- Prioritizes RAG for financial content
- Falls back to Gemini if RAG fails

### YouTube Transcript (`src/services/youtubeTranscript.ts`)
```typescript
await fetchYouTubeTranscript(videoId, ['en', 'hi', 'ta', 'bn', 'mr'])
```

## Middleware

### Authentication (`src/middleware/auth.ts`)
```typescript
// Validates JWT token
// Attaches user to req.user
// Returns 401/403 on invalid token
```

### Error Handler (`src/middleware/errorHandler.ts`)
```typescript
// Catches all errors
// Returns 400 with error message
```

## Utils

### Platform Detector (`src/utils/platformDetector.ts`)
```typescript
detectPlatform(url) // Returns 'YouTube' | 'Instagram' | 'Unknown'
```

### YouTube ID Extractor (`src/utils/youtubeIdExtractor.ts`)
```typescript
extractYouTubeId(url) // Returns 11-char video ID or empty string
```

## Caching

- Transcripts cached per user + video URL
- 7-day TTL (automatic expiration)
- Subsequent requests return cached results instantly

## Error Logging

Fact-checking errors logged to:
```
fact_checker_errors.log
```

Format:
```
[2025-10-18T12:34:56.789Z] Error description: {
  "error": "...",
  "transcript": "..."
}
```

## Authentication Flow

1. User registers/logs in → JWT token issued (1 hour expiry)
2. Token sent in `Authorization: Bearer <token>` header
3. Middleware validates token and attaches user to request
4. Protected routes access `req.user.id` and `req.user.email`

## Deployment

Configured for:
- Render
- Heroku
- Railway

**Requirements:**
- Node.js 20.x
- MongoDB instance
- Gemini API key
- RAG API running separately

**Start Command:**
```bash
npm start
```

**Port:**
- Listens on `0.0.0.0:${PORT}` for external access

## Notes

- Max transcript length: 5000 characters
- JWT tokens expire in 1 hour
- MongoDB connection required on startup
- Instagram transcript service not implemented
- RAG API must be available at configured URL
