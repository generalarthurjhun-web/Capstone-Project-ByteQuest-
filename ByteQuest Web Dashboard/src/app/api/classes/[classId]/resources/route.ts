import { randomUUID } from "node:crypto";
import { NextResponse } from "next/server";
import { z } from "zod";
import { getServerProfile } from "@/lib/auth/server";
import {
  ALLOWED_LEARNING_RESOURCE_TYPES,
  isAllowedLearningResourceMime,
  LEARNING_RESOURCE_BUCKET,
  MAX_LEARNING_RESOURCE_BYTES,
} from "@/lib/resources/policy";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

const classIdSchema = z.string().uuid();
const resourceMetadataSchema = z.object({
  title: z.string().trim().min(2).max(300),
  description: z.string().trim().max(2000).optional(),
});

export async function POST(
  request: Request,
  { params }: { params: Promise<{ classId: string }> },
) {
  const actor = await getServerProfile();
  if (!actor || actor.role !== "instructor" || actor.status !== "active") {
    return NextResponse.json({ error: "Active Instructor access is required." }, { status: 403 });
  }

  const parsedClassId = classIdSchema.safeParse((await params).classId);
  if (!parsedClassId.success) {
    return NextResponse.json({ error: "Invalid class identifier." }, { status: 400 });
  }

  const formData = await request.formData().catch(() => null);
  const file = formData?.get("file");
  const parsedMetadata = resourceMetadataSchema.safeParse({
    title: formData?.get("title"),
    description: formData?.get("description") || undefined,
  });

  if (!(file instanceof File) || !parsedMetadata.success) {
    return NextResponse.json(
      { error: "Provide a file, a 2–300 character title, and an optional description." },
      { status: 400 },
    );
  }

  // Check class ownership before touching private Storage. This prevents an
  // out-of-scope Instructor request from creating an object that must later be
  // rolled back and keeps the API's denial contract deterministic.
  const supabase = await createServerSupabaseClient();
  const { data: ownedClass, error: scopeError } = await supabase
    .from("classes")
    .select("id")
    .eq("id", parsedClassId.data)
    .eq("instructor_id", actor.userId)
    .eq("status", "active")
    .maybeSingle();
  if (scopeError || !ownedClass) {
    return NextResponse.json({ error: "You can upload resources only to your own active class." }, { status: 403 });
  }

  if (!isAllowedLearningResourceMime(file.type)) {
    return NextResponse.json(
      { error: "Only PDF, JPEG, PNG, WebP, MP4, and WebM learning resources are allowed." },
      { status: 415 },
    );
  }

  if (file.size < 1 || file.size > MAX_LEARNING_RESOURCE_BYTES) {
    return NextResponse.json(
      { error: "The file must be larger than 0 bytes and no more than 50 MB." },
      { status: 413 },
    );
  }

  const resourceId = randomUUID();
  const extension = ALLOWED_LEARNING_RESOURCE_TYPES[file.type];
  const storagePath = `classes/${parsedClassId.data}/resources/${resourceId}/resource.${extension}`;
  const admin = createAdminSupabaseClient();
  const bytes = Buffer.from(await file.arrayBuffer());

  const { error: uploadError } = await admin.storage
    .from(LEARNING_RESOURCE_BUCKET)
    .upload(storagePath, bytes, {
      contentType: file.type,
      upsert: false,
      cacheControl: "3600",
    });

  if (uploadError) {
    return NextResponse.json(
      { error: "The resource could not be stored. Verify the file and try again." },
      { status: 400 },
    );
  }

  const { data, error } = await supabase.rpc("create_learning_resource", {
    p_resource_id: resourceId,
    p_class_id: parsedClassId.data,
    p_title: parsedMetadata.data.title,
    p_description: parsedMetadata.data.description ?? "",
    p_storage_path: storagePath,
    p_mime_type: file.type,
    p_size_bytes: file.size,
  });

  if (error || !data) {
    await admin.storage.from(LEARNING_RESOURCE_BUCKET).remove([storagePath]);
    const message = error?.message.includes("CLASS_SCOPE_DENIED")
      ? "You can upload resources only to your own active class."
      : "Resource metadata could not be committed; the uploaded object was rolled back.";
    return NextResponse.json({ error: message }, { status: error ? 403 : 500 });
  }

  return NextResponse.json({ resource: data }, { status: 201 });
}
