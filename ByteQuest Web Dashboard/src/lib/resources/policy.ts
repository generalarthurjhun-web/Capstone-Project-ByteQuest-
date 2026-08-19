export const LEARNING_RESOURCE_BUCKET = "learning-resources";
export const MAX_LEARNING_RESOURCE_BYTES = 50 * 1024 * 1024;

export const ALLOWED_LEARNING_RESOURCE_TYPES = {
  "application/pdf": "pdf",
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "video/mp4": "mp4",
  "video/webm": "webm",
} as const;

export type AllowedLearningResourceMime = keyof typeof ALLOWED_LEARNING_RESOURCE_TYPES;

export function isAllowedLearningResourceMime(
  value: string,
): value is AllowedLearningResourceMime {
  return value in ALLOWED_LEARNING_RESOURCE_TYPES;
}
