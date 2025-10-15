# Use official Python image
FROM python:3.10-slim

WORKDIR /app

# Copy Python requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy only app.py
COPY app.py ./

# Copy other files
COPY .env ./
COPY IndianFinancialNews.csv ./

# Expose port
EXPOSE 8000

# Run FastAPI app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]

