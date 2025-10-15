// src/routes/history.ts
import { Router, Request, Response, NextFunction } from 'express';
import { authenticateToken } from '../middleware/auth';
import { TranscriptModel } from '../models/transcriptModel';

const router = Router();

// Apply authentication middleware
router.use(authenticateToken);

// GET /api/history - Fetch user's search history with full transcript details
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const skip = (page - 1) * limit;

    const total = await TranscriptModel.countDocuments({ user: req.user!.id });
    const transcripts = await TranscriptModel.find({ user: req.user!.id })
      .select('videoURL platform normalizedTranscript isFinancial factCheck createdAt')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 }) // Newest first
      .lean();

    res.status(200).json({
      message: 'Search history retrieved successfully',
      data: {
        history: transcripts.map(t => ({
          videoURL: t.videoURL,
          platform: t.platform,
          normalizedTranscript: t.normalizedTranscript,
          isFinancial: t.isFinancial,
          factCheck: t.factCheck,
          createdAt: t.createdAt,
        })),
        pagination: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

export default router;