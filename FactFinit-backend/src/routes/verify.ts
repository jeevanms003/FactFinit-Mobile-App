// src/routes/verify.ts
import { Router, Request, Response, NextFunction } from 'express';
import { authenticateToken } from '../middleware/auth';
import { VerifyRequest } from '../interfaces/verifyRequest';
import { TranscriptSegment } from '../interfaces/transcript';
import { FactCheckResult } from '../services/factChecker';
import { detectPlatform } from '../utils/platformDetector';
import { extractYouTubeId } from '../utils/youtubeIdExtractor';
import { extractInstagramId } from '../utils/instagramIdExtractor';
import { fetchYouTubeTranscript } from '../services/youtubeTranscript';
import { fetchInstagramTranscript } from '../services/instagramTranscript';
import { normalizeTranscript } from '../services/factChecker';
import { TranscriptModel } from '../models/transcriptModel';

const router = Router();

// Apply authentication middleware to all /api/verify routes
router.use(authenticateToken);

// GET /api/verify - Fetch all fact-checked videos for the authenticated user
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

    if (!transcripts.length) {
      return res.status(200).json({
        message: 'No fact-checked videos found',
        data: {
          transcripts: [],
          pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
          },
        },
      });
    }

    res.status(200).json({
      message: 'Fact-checked videos retrieved successfully',
      data: {
        transcripts: transcripts.map(t => ({
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

// POST /api/verify - Process new video
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { videoURL, platform: providedPlatform, language }: VerifyRequest = req.body;

    if (!videoURL || videoURL.trim() === '') {
      throw new Error('videoURL is required and cannot be empty');
    }

    let cleanedURL = videoURL.trim();
    if (!cleanedURL.startsWith('http://') && !cleanedURL.startsWith('https://')) {
      cleanedURL = `https://${cleanedURL}`;
    }
    try {
      cleanedURL = new URL(cleanedURL).toString();
    } catch {
      throw new Error('Invalid videoURL format');
    }

    const normalizedPlatform = providedPlatform
      ? providedPlatform.toLowerCase() === 'youtube'
        ? 'YouTube'
        : providedPlatform.toLowerCase() === 'instagram'
        ? 'Instagram'
        : providedPlatform
      : detectPlatform(cleanedURL);

    if (normalizedPlatform === 'Unknown') {
      throw new Error('Unsupported platform');
    }

    const cachedTranscript = await TranscriptModel.findOne({ videoURL: cleanedURL, user: req.user!.id }).lean();
    if (cachedTranscript) {
      console.log('Cached document:', cachedTranscript);
      return res.status(200).json({
        message: 'Transcript retrieved from cache',
        data: {
          videoURL: cleanedURL,
          platform: normalizedPlatform,
          transcript: cachedTranscript.transcript,
          normalizedTranscript: cachedTranscript.normalizedTranscript,
          isFinancial: cachedTranscript.isFinancial ?? false,
          factCheck: cachedTranscript.factCheck ?? { claims: [], sources: [] },
        },
      });
    }

    const desiredLanguages = ['en', 'hi', 'ta', 'bn', 'mr'];
    if (language && !desiredLanguages.includes(language)) {
      desiredLanguages.push(language);
    }

    let transcript: Record<string, TranscriptSegment[] | string>;
    if (normalizedPlatform === 'YouTube') {
      const videoId = extractYouTubeId(cleanedURL);
      if (!videoId) {
        throw new Error('Could not extract YouTube video ID');
      }
      console.log(`Processing YouTube video ID: ${videoId}`);
      transcript = await fetchYouTubeTranscript(videoId, desiredLanguages);
    } else if (normalizedPlatform === 'Instagram') {
      const videoId = extractInstagramId(cleanedURL);
      if (!videoId) {
        throw new Error('Could not extract Instagram video ID');
      }
      console.log(`Processing Instagram video ID: ${videoId}`);
      transcript = await fetchInstagramTranscript(cleanedURL, desiredLanguages);
    } else {
      throw new Error('Platform not supported');
    }

    if (!transcript || Object.keys(transcript).length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Transcript not found for this video.',
      });
    }

    const factCheckResult: FactCheckResult = await normalizeTranscript(transcript);

    const cleanedFactCheck = {
      claims: factCheckResult.factCheck.claims.map(claim => ({
        claim: claim.claim,
        isAccurate: claim.isAccurate,
        explanation: claim.explanation,
      })),
      sources: factCheckResult.factCheck.sources || [],
    };

    await TranscriptModel.create({
      videoURL: cleanedURL,
      platform: normalizedPlatform,
      transcript,
      normalizedTranscript: factCheckResult.normalizedTranscript,
      isFinancial: factCheckResult.isFinancial,
      factCheck: cleanedFactCheck,
      user: req.user!.id, // Associate with authenticated user
    });

    res.status(200).json({
      message: 'Transcript processed successfully',
      data: {
        videoURL: cleanedURL,
        platform: normalizedPlatform,
        transcript,
        normalizedTranscript: factCheckResult.normalizedTranscript,
        isFinancial: factCheckResult.isFinancial,
        factCheck: cleanedFactCheck,
      },
    });
  } catch (error) {
    next(error);
  }
});

export default router;