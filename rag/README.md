# FactFinit RAG API

## Installation
```bash
pip install fastapi pydantic python-dotenv pandas chromadb sentence-transformers google-generativeai uvicorn
```

## Environment Setup

Create `.env` file:
```env
GEMINI_API_KEY=your-gemini-api-key
```

## Configuration

Update paths in main file:
```python
DB_PATH = "./database"           # ChromaDB storage path
CSV_PATH = "sample_IndianFinancialNews.csv"  # Financial news dataset
```

## Run
```bash
# Development
uvicorn main:app --reload --host 0.0.0.0 --port 8001

# Production
uvicorn main:app --host 0.0.0.0 --port 8001
```

## API Endpoint

### Query Financial Data
```http
POST /query
Content-Type: application/json

{
  "query": "What was the gold price in 2015?"
}
```

**Response:**
```json
{
  "answer": "Based on financial news from 2015, the average gold price was approximately Rs 26,400 per 10g..."
}
```

**Out of Context Response:**
```json
{
  "answer": "OUT OF CONTEXT"
}
```

## How It Works

### 1. Database Loading
- Reads CSV file with columns: `Date`, `Title`, `Description`
- Converts to embeddings using `all-MiniLM-L6-v2` model
- Stores in ChromaDB (persistent vector database)
- Auto-loads on first startup if database empty

### 2. Query Processing
1. User sends query
2. Query embedded using same model
3. ChromaDB retrieves top 5 relevant passages (sorted by date, newest first)
4. Passages combined into context prompt
5. Gemini AI generates answer based on context
6. Returns "OUT OF CONTEXT" if query unrelated to financial data

### 3. Embedding Model
```python
SentenceTransformer("all-MiniLM-L6-v2")
# Free, local, 384-dimensional embeddings
# Fast encoding with batching support
```

## CSV Format

Required columns:
```csv
Date,Title,Description
2015-01-15,"Gold Prices Rise","Gold prices increased to Rs 26,400 per 10g..."
2015-02-20,"Market Update","Stock market shows strong performance..."
```

## Database Structure

### ChromaDB Collection
```python
{
  "name": "csv_db",
  "documents": ["Title: ...\nDescription: ..."],
  "metadatas": [
    {
      "date": "2015-01-15",
      "title": "Gold Prices Rise",
      "description": "Gold prices increased..."
    }
  ],
  "ids": ["doc_0", "doc_1", ...]
}
```

## Functions

### Load CSV to Database
```python
load_csv_to_db(csv_path)
# Encodes all documents in batches of 32
# Inserts to ChromaDB in chunks of 5000
# Returns total document count
```

### Get Relevant Passages
```python
get_relevant_passages(query, n_results=5)
# Returns top 5 passages sorted by date (newest first)
# Returns: [(document, metadata), ...]
```

### Make Prompt
```python
make_prompt(query, passages)
# Combines query with context passages
# Instructs Gemini to respond or say "OUT OF CONTEXT"
```

## CORS Configuration
```python
allow_origins=["*"]  # Change to specific domains in production
allow_credentials=True
allow_methods=["*"]
allow_headers=["*"]
```

## Error Handling

### Empty Database
```json
{
  "detail": "Database empty. Add CSV first."
}
```

### Missing CSV
```
❌ CSV file not found at sample_IndianFinancialNews.csv. Please check path.
```

### Gemini API Error
```json
{
  "detail": "API error message"
}
```

## Batch Processing

- **Embedding Batch Size:** 32 documents
- **ChromaDB Insert Batch:** 5000 documents
- Prevents memory overflow for large datasets
- Shows progress during loading

## Logging
```
📦 Database empty. Loading CSV embeddings...
Encoding embeddings...
✅ Inserted batch 1/3 (5000 / 12000 docs)
✅ Inserted batch 2/3 (10000 / 12000 docs)
✅ Inserted batch 3/3 (12000 / 12000 docs)
🎉 Successfully loaded 12000 documents into ChromaDB.
```

## Integration with Backend

Backend calls RAG API:
```typescript
const ragResponse = await axios.post(
  'http://localhost:8001/query',
  { query: transcriptText },
  { timeout: 15000 }
);

const { answer, passages } = ragResponse.data;
```

## Performance

- **Embedding Model:** 384 dimensions
- **Vector Search:** Fast similarity search with ChromaDB
- **Batch Encoding:** ~1000 docs/second on CPU
- **Query Time:** <1 second for 5 results

## Deployment

**Requirements:**
- Python 3.8+
- CSV file with financial news
- Gemini API key

**Port:** 8001 (configurable)

**Storage:** `./database` directory for ChromaDB persistence

## Notes

- Database persists between restarts
- Only loads CSV if database empty
- Returns most recent relevant passages first
- Free local embeddings (no API costs)
- Gemini used only for final answer generation
