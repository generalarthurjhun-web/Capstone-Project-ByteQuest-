import "server-only";

import { z } from "zod";

export const quizItemTypeSchema = z.enum([
  "multiple_choice",
  "true_false",
  "identification",
  "scenario_based",
]);

export const quizDraftQuestionSchema = z.object({
  question: z.string().trim().min(5).max(2000),
  type: quizItemTypeSchema,
  choices: z.array(z.string().trim().min(1).max(300)).max(6),
  correctAnswer: z.string().trim().min(1).max(500),
  explanation: z.string().trim().min(1).max(1500),
  competency: z.string().trim().min(2).max(300),
  coc: z.string().trim().min(2).max(300),
  learningOutcome: z.string().trim().min(2).max(1000),
});

export const quizDraftResponseSchema = z.object({
  questions: z.array(quizDraftQuestionSchema).min(1).max(10),
});

export const quizDraftItemSchema = z.object({
  item_type: quizItemTypeSchema,
  prompt: z.string().trim().min(5).max(2000),
  options: z.array(z.string().trim().min(1).max(300)).max(6),
  correct_answer: z.string().trim().min(1).max(500),
  explanation: z.string().trim().min(1).max(1500),
});

export type QuizItemType = z.infer<typeof quizItemTypeSchema>;
export type QuizDraftQuestion = z.infer<typeof quizDraftQuestionSchema>;
export type QuizDraftItem = z.infer<typeof quizDraftItemSchema>;

export interface QuizGenerationGrounding {
  qualification: { code: string; title: string };
  source: { id: string; title: string; edition: string; reference: string };
  coc: { id: string; code: string; title: string };
  competency: { id: string; code: string; title: string; sourceTrace: string };
  module: { id: string; title: string; version: number; sourceTrace: unknown };
  activity: { id: string; title: string; version: number; instructions: string | null };
  mission: {
    id: string;
    number: number;
    title: string;
    objective: string;
    scenario: string;
    skillsAssessed: string[];
  };
  rubric: { id: string; title: string; version: number };
  criteria: Array<{
    code: string;
    title: string;
    description: string | null;
    required: boolean;
    sourceTrace: string;
  }>;
}

export interface QuizDraftRequest {
  quizTitle: string;
  topic: string;
  instructorContext: string | null;
  difficulty: "foundation" | "intermediate" | "advanced";
  itemCount: number;
  itemTypes: QuizItemType[];
  grounding: QuizGenerationGrounding;
}

function normalize(value: string) {
  return value.trim().replace(/\s+/g, " ");
}

function validateQuestionContract(question: QuizDraftQuestion, request: QuizDraftRequest) {
  if (!request.itemTypes.includes(question.type)) return false;
  if (normalize(question.competency) !== normalize(request.grounding.competency.title)) return false;
  if (normalize(question.coc) !== normalize(`${request.grounding.coc.code} - ${request.grounding.coc.title}`)) return false;
  if (normalize(question.learningOutcome) !== normalize(request.grounding.mission.objective)) return false;

  if (question.type === "multiple_choice" || question.type === "scenario_based") {
    const uniqueChoices = new Set(question.choices.map((choice) => normalize(choice).toLocaleLowerCase()));
    return (
      question.choices.length >= 2 &&
      uniqueChoices.size === question.choices.length &&
      question.choices.includes(question.correctAnswer)
    );
  }

  if (question.type === "true_false") {
    return question.choices.length === 0 && ["true", "false"].includes(question.correctAnswer.toLocaleLowerCase());
  }

  return question.choices.length === 0;
}

export function normalizeAndValidateQuizDraft(payload: unknown, request: QuizDraftRequest): QuizDraftItem[] {
  const parsed = quizDraftResponseSchema.safeParse(payload);
  if (!parsed.success || parsed.data.questions.length !== request.itemCount) {
    throw new Error("AI_DRAFT_CONTRACT_INVALID");
  }

  const prompts = new Set<string>();
  for (const question of parsed.data.questions) {
    if (!validateQuestionContract(question, request)) throw new Error("AI_DRAFT_QUESTION_INVALID");
    const key = normalize(question.question).toLocaleLowerCase();
    if (prompts.has(key)) throw new Error("AI_DRAFT_DUPLICATE_QUESTION");
    prompts.add(key);
  }

  return parsed.data.questions.map((question) => ({
    item_type: question.type,
    prompt: normalize(question.question),
    options: question.choices.map(normalize),
    correct_answer:
      question.type === "true_false" ? question.correctAnswer.toLocaleLowerCase() : normalize(question.correctAnswer),
    explanation: normalize(question.explanation),
  }));
}
