// src/routes/auth.ts
import { Router, Request, Response, NextFunction } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { UserModel } from '../models/userModel';

const router = Router();

interface LoginRequest {
  email: string;
  password: string;
}

interface RegisterRequest {
  email: string;
  password: string;
}

router.post('/login', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, password }: LoginRequest = req.body;

    if (!email || !password) {
      throw new Error('Email and password are required');
    }

    const user = await UserModel.findOne({ email }).select('+password');
    if (!user) {
      throw new Error('Invalid credentials');
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new Error('Invalid credentials');
    }

    const token = jwt.sign(
      { email: user.email, id: user._id.toString() },
      process.env.JWT_SECRET || 'your-secure-jwt-secret',
      { expiresIn: '1h' }
    );

    res.status(200).json({
      message: 'Login successful',
      token,
    });
  } catch (error) {
    next(error);
  }
});

router.post('/register', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, password }: RegisterRequest = req.body;

    if (!email || !password) {
      throw new Error('Email and password are required');
    }

    const existingUser = await UserModel.findOne({ email }).lean();
    if (existingUser) {
      throw new Error('User already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await UserModel.create({
      email,
      password: hashedPassword,
    });

    const token = jwt.sign(
      { email: user.email, id: user._id.toString() },
      process.env.JWT_SECRET || 'your-secure-jwt-secret',
      { expiresIn: '1h' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      token,
    });
  } catch (error) {
    next(error);
  }
});

export default router;