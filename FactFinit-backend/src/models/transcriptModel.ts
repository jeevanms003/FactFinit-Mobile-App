// src/models/transcriptModel.ts
import { Schema, model, Document } from 'mongoose';
import { TranscriptSegment } from '../interfaces/transcript';

interface ITranscript extends Document {
  videoURL: string;
  platform: string;
  transcript: Record<string, TranscriptSegment[] | string>;
  normalizedTranscript: string;
  isFinancial: boolean;
  factCheck: {
    claims: Array<{ claim: string; isAccurate: boolean; explanation: string }>;
    sources?: Array<{ title: string; url: string; snippet: string }>;
  };
  user: Schema.Types.ObjectId; // Reference to User
  createdAt?: Date;
}

const TranscriptSchema = new Schema<ITranscript>(
  {
    videoURL: { type: String, required: true, index: true },
    platform: { type: String, required: true },
    transcript: { type: Object, required: true },
    normalizedTranscript: { type: String, required: true },
    isFinancial: { type: Boolean, required: true, default: false },
    factCheck: {
      claims: [
        {
          claim: { type: String, required: true },
          isAccurate: { type: Boolean, required: true },
          explanation: { type: String, required: true },
        },
      ],
      sources: [
        {
          title: { type: String, required: false },
          url: { type: String, required: false },
          snippet: { type: String, required: false },
        },
      ],
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    createdAt: { type: Date, default: Date.now },
  },
  { strict: 'throw' }
);

TranscriptSchema.index({ createdAt: 1 }, { expireAfterSeconds: 604800 }); // 7 days TTL

export const TranscriptModel = model<ITranscript>('Transcript', TranscriptSchema);