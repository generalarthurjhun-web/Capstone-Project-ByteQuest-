import { NextResponse } from "next/server";
import { z } from "zod";
import { getServerProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

const paramsSchema = z.object({ classId: z.string().uuid(), resourceId: z.string().uuid() });
const deleteSchema = z.object({ reason: z.string().trim().min(5).max(1000) });

async function scopedResource(classId: string, resourceId: string) {
  const supabase = await createServerSupabaseClient();
  return supabase
    .from("learning_resources")
    .select("id,class_id,storage_bucket,storage_path,status")
    .eq("id", resourceId)
    .eq("class_id", classId)
    .maybeSingle();
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ classId: string; resourceId: string }> },
) {
  const actor = await getServerProfile();
  if (!actor || actor.status !== "active") {
    return NextResponse.json({ error: "Authentication is required." }, { status: 403 });
  }

  const parsed = paramsSchema.safeParse(await params);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid resource identifier." }, { status: 400 });
  }

  const { data: resource } = await scopedResource(parsed.data.classId, parsed.data.resourceId);
  if (!resource || resource.status !== "active") {
    return NextResponse.json({ error: "Resource not found or not authorized." }, { status: 404 });
  }

  const { data, error } = await createAdminSupabaseClient().storage
    .from(resource.storage_bucket)
    .createSignedUrl(resource.storage_path, 120);

  if (error || !data?.signedUrl) {
    return NextResponse.json({ error: "A temporary resource link could not be created." }, { status: 502 });
  }

  return NextResponse.redirect(data.signedUrl, 307);
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ classId: string; resourceId: string }> },
) {
  const actor = await getServerProfile();
  if (
    !actor ||
    actor.status !== "active" ||
    (actor.role !== "instructor" && actor.role !== "admin")
  ) {
    return NextResponse.json({ error: "Active staff access is required." }, { status: 403 });
  }

  const parsedParams = paramsSchema.safeParse(await params);
  const parsedBody = deleteSchema.safeParse(await request.json().catch(() => null));
  if (!parsedParams.success || !parsedBody.success) {
    return NextResponse.json({ error: "A valid resource and deletion reason are required." }, { status: 400 });
  }

  const { data: resource } = await scopedResource(
    parsedParams.data.classId,
    parsedParams.data.resourceId,
  );
  if (!resource) {
    return NextResponse.json({ error: "Resource not found or not authorized." }, { status: 404 });
  }

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.rpc("delete_learning_resource", {
    p_resource_id: parsedParams.data.resourceId,
    p_reason: parsedBody.data.reason,
  });
  if (error) {
    return NextResponse.json({ error: "The resource could not be archived." }, { status: 403 });
  }

  const { error: storageError } = await createAdminSupabaseClient().storage
    .from(resource.storage_bucket)
    .remove([resource.storage_path]);

  if (storageError) {
    return NextResponse.json(
      { error: "The resource was archived, but storage cleanup requires an Administrator retry." },
      { status: 502 },
    );
  }

  return NextResponse.json({ deleted: true });
}
