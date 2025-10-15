from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import pandas as pd
import math
from datetime import datetime
from dotenv import load_dotenv
import chromadb
from chromadb import EmbeddingFunction
from sentence_transformers import SentenceTransformer
from fastapi.middleware.cors import CORSMiddleware

# ------------------ CONFIG ------------------
load_dotenv()

DB_PATH = "./database"
CSV_PATH = "sample_IndianFinancialNews.csv"

app = FastAPI(title="RAG API")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to your needs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------ EMBEDDINGS ------------------
class LocalEmbeddingFunction(EmbeddingFunction):
    def __init__(self):
        self.model = SentenceTransformer("all-MiniLM-L6-v2")  # free local model

    def __call__(self, input):
        if isinstance(input, str):
            input = [input]
        return self.model.encode(input, show_progress_bar=False).tolist()


# ------------------ CHROMADB ------------------
chroma_client = chromadb.PersistentClient(path=DB_PATH)
db = chroma_client.get_or_create_collection(
    name="csv_db",
    embedding_function=LocalEmbeddingFunction()
)


# ------------------ LOAD CSV ------------------
def load_csv_to_db(csv_path):
    df = pd.read_csv(csv_path)
    required_columns = ['Date', 'Title', 'Description']
    for col in required_columns:
        if col not in df.columns:
            raise ValueError(f"CSV must contain '{col}' column")

    df['Date'] = pd.to_datetime(df['Date'])
    df = df.sort_values('Date')

    docs = [f"Title: {row['Title']}\nDescription: {row['Description']}" for _, row in df.iterrows()]
    metas = [
        {
            'date': row['Date'].strftime('%Y-%m-%d'),
            'title': row['Title'],
            'description': row['Description']
        }
        for _, row in df.iterrows()
    ]
    ids = [f"doc_{i}" for i in range(len(df))]

    # 🧠 Encode all embeddings once
    embed_fn = db._embedding_function.model
    print("Encoding embeddings...")
    embeddings = embed_fn.encode(docs, batch_size=32, show_progress_bar=True).tolist()

    # ✅ Add in chunks to avoid Chroma batch limit
    batch_size = 5000
    num_batches = math.ceil(len(docs) / batch_size)
    for i in range(num_batches):
        start = i * batch_size
        end = min(start + batch_size, len(docs))
        db.add(
            documents=docs[start:end],
            metadatas=metas[start:end],
            ids=ids[start:end],
            embeddings=embeddings[start:end]
        )
        print(f"✅ Inserted batch {i + 1}/{num_batches} ({end} / {len(docs)} docs)")

    print(f"🎉 Successfully loaded {len(docs)} documents into ChromaDB.")
    return len(docs)


# ------------------ INIT (PRELOAD) ------------------
if db.count() == 0:
    print("📦 Database empty. Loading CSV embeddings...")
    if not os.path.exists(CSV_PATH):
        print(f"❌ CSV file not found at {CSV_PATH}. Please check path.")
    else:
        load_csv_to_db(CSV_PATH)
else:
    print(f"✅ Database already loaded with {db.count()} entries.")


# ------------------ QUERY ------------------
def get_relevant_passages(query, n_results=5):
    results = db.query(query_texts=[query], n_results=n_results, include=['documents', 'metadatas'])
    combined = list(zip(results['documents'][0], results['metadatas'][0]))
    return sorted(combined, key=lambda x: x[1]['date'], reverse=True)


def make_prompt(query, passages):
    context = ""
    for doc, meta in passages:
        context += f"Date: {meta['date']}\nTitle: {meta['title']}\nDescription: {meta['description']}\n---\n"

    return f"""
transcript: {query}

Additional Information:
{context}
, respond
If the transcript is not related to the provided information, respond with 'OUT OF CONTEXT'. Else provide a detailed and accurate answer based on the provided information.
Your answer:
"""


class QueryRequest(BaseModel):
    query: str


@app.post("/query")
def ask_question(req: QueryRequest):
    if db.count() == 0:
        raise HTTPException(status_code=400, detail="Database empty. Add CSV first.")
    passages = get_relevant_passages(req.query)
    prompt = make_prompt(req.query, passages)

    # Gemini answering section
    try:
        from google import generativeai as genai
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
        model = genai.GenerativeModel(model_name="gemini-2.5-flash")
        response = model.generate_content(prompt)
        return {"answer": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
