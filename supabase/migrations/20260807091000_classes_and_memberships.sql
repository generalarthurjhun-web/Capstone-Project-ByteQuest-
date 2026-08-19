-- ByteQuest LMS-lite class ownership and historical membership model.

begin;

do $$
begin
  create type public.class_status as enum ('active', 'archived');
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.membership_status as enum ('active', 'deactivated');
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(btrim(title)) between 2 and 160),
  class_code text,
  instructor_id uuid not null references auth.users(id) on delete restrict,
  status public.class_status not null default 'active',
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete set null,
  archive_reason text,
  constraint classes_archive_details_check check (
    (status <> 'archived'::public.class_status)
    or (archived_at is not null and nullif(btrim(archive_reason), '') is not null)
  )
);

create unique index if not exists classes_class_code_unique_idx
  on public.classes(lower(class_code))
  where class_code is not null;
create index if not exists classes_instructor_status_idx
  on public.classes(instructor_id, status);

create table if not exists public.class_memberships (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete restrict,
  learner_id uuid not null references auth.users(id) on delete restrict,
  status public.membership_status not null default 'active',
  enrolled_by uuid not null references auth.users(id) on delete restrict,
  enrolled_at timestamptz not null default now(),
  deactivated_by uuid references auth.users(id) on delete set null,
  deactivated_at timestamptz,
  deactivation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint class_memberships_deactivation_details_check check (
    (status <> 'deactivated'::public.membership_status)
    or (
      deactivated_at is not null
      and deactivated_by is not null
      and nullif(btrim(deactivation_reason), '') is not null
    )
  )
);

create unique index if not exists class_memberships_one_active_idx
  on public.class_memberships(class_id, learner_id)
  where status = 'active'::public.membership_status;
create index if not exists class_memberships_learner_status_idx
  on public.class_memberships(learner_id, status);
create index if not exists class_memberships_class_status_idx
  on public.class_memberships(class_id, status);

drop trigger if exists trg_classes_updated_at on public.classes;
create trigger trg_classes_updated_at
before update on public.classes
for each row execute function public.set_updated_at();

drop trigger if exists trg_class_memberships_updated_at on public.class_memberships;
create trigger trg_class_memberships_updated_at
before update on public.class_memberships
for each row execute function public.set_updated_at();

alter table public.classes enable row level security;
alter table public.class_memberships enable row level security;

create or replace function public.instructor_owns_class(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.classes c
    where c.id = p_class_id
      and c.instructor_id = (select auth.uid())
      and c.status = 'active'::public.class_status
      and public.is_instructor()
  )
$$;

create or replace function public.learner_is_enrolled(
  p_class_id uuid,
  p_learner_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.class_memberships cm
    where cm.class_id = p_class_id
      and cm.learner_id = coalesce(p_learner_id, (select auth.uid()))
      and cm.status = 'active'::public.membership_status
  )
$$;

revoke all on function public.instructor_owns_class(uuid) from public, anon;
revoke all on function public.learner_is_enrolled(uuid, uuid) from public, anon;
grant execute on function public.instructor_owns_class(uuid) to authenticated, service_role;
grant execute on function public.learner_is_enrolled(uuid, uuid) to authenticated, service_role;

commit;
