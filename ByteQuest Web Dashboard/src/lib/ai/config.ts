import "server-only";

export const OPENROUTER_CHAT_COMPLETIONS_URL = "https://openrouter.ai/api/v1/chat/completions";
export const DEFAULT_OPENROUTER_MODEL = "openrouter/free";

export interface QuizAiConfiguration {
  provider: "openrouter";
  apiKey: string;
  model: string;
  endpoint: typeof OPENROUTER_CHAT_COMPLETIONS_URL;
  timeoutMs: number;
}

export class QuizAiConfigurationError extends Error {
  constructor() {
    super("OPENROUTER_NOT_CONFIGURED");
    this.name = "QuizAiConfigurationError";
  }
}

export function getQuizAiConfiguration(): QuizAiConfiguration {
  const apiKey = process.env.OPENROUTER_API_KEY?.trim();
  if (!apiKey) throw new QuizAiConfigurationError();

  return {
    provider: "openrouter",
    apiKey,
    model: process.env.OPENROUTER_MODEL?.trim() || DEFAULT_OPENROUTER_MODEL,
    endpoint: OPENROUTER_CHAT_COMPLETIONS_URL,
    timeoutMs: 45_000,
  };
}
