// src/services/factChecker.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import axios from 'axios';
import { TranscriptSegment } from '../interfaces/transcript';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');
const RAG_API_URL = process.env.RAG_API_URL || 'http://localhost:8001/query';

// Simple error logging
const logError = (message: string, data: any) => {
  const log = `[${new Date().toISOString()}] ${message}: ${JSON.stringify(data, null, 2)}\n`;
  fs.appendFileSync('fact_checker_errors.log', log);
};

export interface FactCheckResult {
  normalizedTranscript: string;
  isFinancial: boolean;
  factCheck: {
    claims: Array<{ claim: string; isAccurate: boolean; explanation: string }>;
    sources?: Array<{ title: string; url: string; snippet: string }>;
  };
}

async function runGeminiFactCheck(combinedText: string, context: string = ''): Promise<FactCheckResult> {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  const prompt = `
You are a professional transcript normalizer and fact-checker. Your task is to process the provided transcript and return a structured JSON response with the following:

1. **Normalized Transcript**: Convert the transcript into a single, cohesive English paragraph that includes all content from the input. Follow these steps:
   - Translate any non-English text to English, preserving the original meaning.
   - Fix grammatical errors and improve sentence structure for clarity and readability.
   - Remove filler words (e.g., "uh", "um", "you know", "like") and repetitive phrases where they do not contribute to meaning.
   - For songs or repetitive content, include all unique content in a natural, flowing paragraph without summarizing or omitting details, combining repeated sections only if they are identical and add no new meaning.
   - If the input is empty or cannot be normalized, return a brief English message indicating the issue.

2. **Financial Detection**: Analyze the transcript to determine if it contains financial content (e.g., stocks, investments, markets, economic advice, prices like gold rates). Return a boolean (true/false) for "isFinancial".

3. **Fact-Checking**:
   - If isFinancial is false, return factCheck as { claims: [], sources: [] }.
   - If isFinancial is true:
     - Identify up to 3 major claims in the transcript.
     - For each claim, provide:
       - claim: The specific claim made (quote verbatim, e.g., "10gm gold was 3000 Rs in 2015").
       - isAccurate: Boolean (true/false) indicating if the claim is correct.
       - explanation: A detailed explanation (100-200 words) of the fact-check, including why it is accurate or inaccurate, key supporting facts or evidence from reliable sources, relevant context, and any caveats or nuances. For numerical claims, verify units (e.g., per gram vs. 10g) and reference sources in the explanation.
     - Provide up to 5 credible sources at the factCheck level (not within claims) with title, URL, and snippet to support fact-checking, referencing them in explanations as needed. Example: { title: "Source Title", url: "https://example.com", snippet: "Relevant excerpt" }.

Return only the JSON object, without markdown, code blocks, or extra formatting.

Input: "${combinedText.replace(/"/g, '\\"')}"
Output format: {
  "normalizedTranscript": "string",
  "isFinancial": boolean,
  "factCheck": {
    "claims": Array<{ "claim": string, "isAccurate": boolean, "explanation": string }>,
    "sources": Array<{ "title": string, "url": string, "snippet": string }>
  }
}
Example output: {
  "normalizedTranscript": "The video discusses credit card interest rates and cash advances.",
  "isFinancial": true,
  "factCheck": {
    "claims": [
      {
        "claim": "Cash advances accrue interest immediately.",
        "isAccurate": true,
        "explanation": "Cash advances typically have no grace period and accrue interest from the transaction date."
      }
    ],
    "sources": [
      {
        "title": "Credit Card Cash Advance Fees",
        "url": "https://www.nerdwallet.com/article/credit-cards/credit-card-cash-advance",
        "snippet": "Unlike credit card purchases, cash advances don’t come with a grace period."
      }
    ]
  }
}
`;

  try {
    const result = await model.generateContent(prompt, { timeout: 20000 });
    const responseText = result.response
      .text()
      .replace(/```json\n|```/g, '')
      .replace(/```[\s\S]*?```/g, '')
      .replace(/\n\s*/g, '')
      .replace(/\s+/g, ' ')
      .trim();
    
    // Log raw response for debugging
    logError('Gemini raw response', { responseText });
    
    let parsedResult: FactCheckResult = JSON.parse(responseText) as FactCheckResult;

    // Clean factCheck.claims to remove any sources field
    parsedResult.factCheck.claims = parsedResult.factCheck.claims.map(claim => ({
      claim: claim.claim,
      isAccurate: claim.isAccurate,
      explanation: claim.explanation,
    }));

    // Ensure sources are at factCheck level
    if (!parsedResult.factCheck.sources) {
      parsedResult.factCheck.sources = [];
    }
    // Move any sources from claims to factCheck.sources
    parsedResult.factCheck.claims.forEach(claim => {
      if ((claim as any).sources) {
        parsedResult.factCheck.sources!.push(...(claim as any).sources);
        delete (claim as any).sources;
      }
    });

    return parsedResult;
  } catch (error) {
    logError('Gemini fact-check failed', { error, transcript: combinedText });
    throw error;
  }
}

async function runRAGFactCheck(combinedText: string): Promise<FactCheckResult> {
  try {
    const ragResponse = await axios.post(
      RAG_API_URL,
      { query: combinedText },
      { timeout: 15000 }
    );
    const { answer, passages } = ragResponse.data;

    const normalizedTranscript = answer === 'OUT OF CONTEXT'
      ? combinedText
      : passages.length > 0
        ? passages.map((p: any) => p.snippet).join(' ')
        : combinedText;

    const isFinancial = answer !== 'OUT OF CONTEXT' && passages.length > 0;

    const claims = answer === 'OUT OF CONTEXT' ? [] : passages.map((p: any, i: number) => ({
      claim: p.title,
      isAccurate: true,
      explanation: `Based on recent financial news: ${p.snippet} (Source: ${p.url})`,
    }));

    return {
      normalizedTranscript,
      isFinancial,
      factCheck: {
        claims,
        sources: passages.map((p: any) => ({
          title: p.title,
          url: p.url,
          snippet: p.snippet,
        })),
      },
    };
  } catch (error) {
    logError('RAG fact-check failed', { error, transcript: combinedText });
    return {
      normalizedTranscript: combinedText,
      isFinancial: false,
      factCheck: { claims: [], sources: [] },
    };
  }
}

async function mergeResults(
  geminiResult: FactCheckResult,
  ragResult: FactCheckResult,
  combinedText: string
): Promise<FactCheckResult> {
  if (ragResult.isFinancial && ragResult.factCheck.claims.length > 0) {
    return {
      normalizedTranscript: geminiResult.normalizedTranscript,
      isFinancial: true,
      factCheck: {
        claims: ragResult.factCheck.claims,
        sources: ragResult.factCheck.sources || [],
      },
    };
  }
  return {
    normalizedTranscript: geminiResult.normalizedTranscript,
    isFinancial: geminiResult.isFinancial,
    factCheck: {
      claims: geminiResult.factCheck.claims,
      sources: geminiResult.factCheck.sources || [],
    },
  };
}

export async function normalizeTranscript(
  transcript: Record<string, TranscriptSegment[] | string>,
  additionalContext: string = ''
): Promise<FactCheckResult> {
  const allSegments: TranscriptSegment[] = [];
  const languages = ['en', 'hi', 'ta', 'bn', 'mr'];

  if (transcript['en'] && Array.isArray(transcript['en'])) {
    allSegments.push(...(transcript['en'] as TranscriptSegment[]));
  } else {
    for (const lang of languages) {
      if (transcript[lang] && Array.isArray(transcript[lang])) {
        allSegments.push(...(transcript[lang] as TranscriptSegment[]));
      }
    }
  }

  if (allSegments.length === 0) {
    console.warn('No valid transcript segments found:', transcript);
    return {
      normalizedTranscript: 'No translatable transcript available',
      isFinancial: false,
      factCheck: { claims: [], sources: [] },
    };
  }

  const combinedText = allSegments.map(t => t.text).join(' ').slice(0, 5000).trim();
  if (!combinedText) {
    console.warn('Combined transcript is empty');
    return {
      normalizedTranscript: 'No translatable transcript available',
      isFinancial: false,
      factCheck: { claims: [], sources: [] },
    };
  }

  const staticFacts = {
    'gold_2015': 'Average gold price in 2015 was Rs 26,400 per 10g (Rs 2,640/g). Source: https://www.bankbazaar.com/gold-rate/gold-rate-trend-in-india.html',
  };
  const context = combinedText.includes('gold') && combinedText.includes('2015') ? staticFacts['gold_2015'] : additionalContext;

  const timeout = 20000;
  const promises = [
    runGeminiFactCheck(combinedText, context).then(res => ({ source: 'Gemini', result: res })),
    runRAGFactCheck(combinedText).then(res => ({ source: 'RAG', result: res })),
  ];

  try {
    const results = await Promise.allSettled(promises);
    let geminiResult: FactCheckResult | null = null;
    let ragResult: FactCheckResult | null = null;

    for (const result of results) {
      if (result.status === 'fulfilled') {
        const { source, result: res } = result.value;
        if (source === 'Gemini') geminiResult = res;
        if (source === 'RAG') ragResult = res;
      } else {
        logError('Fact-check promise rejected', { reason: result.reason, transcript: combinedText });
      }
    }

    if (!geminiResult && !ragResult) {
      throw new Error('Both Gemini and RAG fact-checkers failed');
    }

    if (!geminiResult) {
      return {
        normalizedTranscript: ragResult!.normalizedTranscript,
        isFinancial: ragResult!.isFinancial,
        factCheck: {
          claims: ragResult!.factCheck.claims,
          sources: ragResult!.factCheck.sources || [],
        },
      };
    }
    if (!ragResult) {
      return {
        normalizedTranscript: geminiResult.normalizedTranscript,
        isFinancial: geminiResult.isFinancial,
        factCheck: {
          claims: geminiResult.factCheck.claims,
          sources: geminiResult.factCheck.sources || [],
        },
      };
    }

    return mergeResults(geminiResult, ragResult, combinedText);
  } catch (error) {
    logError('Fact-checking failure', { error, transcript: combinedText });
    return {
      normalizedTranscript: combinedText,
      isFinancial: false,
      factCheck: { claims: [], sources: [] },
    };
  }
}