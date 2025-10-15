import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import verifyRouter from './routes/verify';
import authRouter from './routes/auth';
import historyRouter from './routes/history';
import errorHandler from './middleware/errorHandler';

// Load environment variables
dotenv.config();

const app: Express = express();

// Validate PORT
const PORT: number = parseInt(process.env.PORT || '9000', 10); // Convert string to number
if (isNaN(PORT)) {
  console.error('Error: PORT is not a valid number');
  process.exit(1);
}

// Validate MONGODB_URI
if (!process.env.MONGODB_URI) {
  console.error('Error: MONGODB_URI is not defined in environment variables');
  process.exit(1);
}

// Connect to MongoDB
mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/verify', verifyRouter);
app.use('/api/auth', authRouter);
app.use('/api/history', historyRouter);

// Error handling middleware
app.use(errorHandler);

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});