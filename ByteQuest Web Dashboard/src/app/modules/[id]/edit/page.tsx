import { redirect } from "next/navigation";

export default async function EditModulePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  redirect(`/modules/${id}`);
}
