// src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { UserModel } from '../models/userModel';

export function authenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Expecting 'Bearer <token>'

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secure-jwt-secret') as { email: string; id: string };
    UserModel.findOne({ email: decoded.email })
      .then(user => {
        if (!user) {
          return res.status(403).json({ error: 'User not found' });
        }
        req.user = { email: decoded.email, id: user._id.toString() }; // Attach email and _id
        next();
      })
      .catch(err => {
        res.status(403).json({ error: 'Invalid token' });
      });
  } catch (error) {
    res.status(403).json({ error: 'Invalid or expired token' });
  }
}

declare global {
  namespace Express {
    interface Request {
      user?: { email: string; id: string }; // Define req.user type
    }
  }
}