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

## API Usage

### 1. Register
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

### 2. Login
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

### 3. Verify Video
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

### 4. Get Fact-Checked Videos
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

### 5. Get Search History
```http
GET /api/history?page=1&limit=10
Authorization: Bearer <token>
```

**Response:** Same as `/api/verify` GET

## Supported Platforms

- YouTube (`youtube.com`, `youtu.be`)
- Instagram (`instagram.com`)

## Supported Languages

- English (en)
- Hindi (hi)
- Tamil (ta)
- Bengali (bn)
- Marathi (mr)

## Notes

- JWT tokens expire in 1 hour
- Transcripts cached for 7 days per user
- Max transcript length: 5000 characters
- MongoDB and RAG API must be running
