begin;

-- ByteQuest quiz drafting now uses OpenRouter through a trusted Next.js route.
-- Existing completed OpenAI generation history is preserved unchanged.
alter table public.ai_quiz_generations alter column provider set default 'openrouter';

revoke all on function public.begin_ai_quiz_generation(uuid,text,jsonb,integer) from public,anon,authenticated;
drop function public.begin_ai_quiz_generation(uuid,text,jsonb,integer);

create function public.begin_ai_quiz_generation(
  p_quiz_version_id uuid,
  p_provider text,
  p_model text,
  p_input_context jsonb,
  p_requested_count integer
)
returns public.ai_quiz_generations
language plpgsql
security definer
set search_path = ''
as $$
declare v_generation public.ai_quiz_generations;
begin
  if not public.is_instructor() then
    raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501';
  end if;
  if btrim(coalesce(p_provider,'')) <> 'openrouter'
     or length(btrim(coalesce(p_model,''))) not between 2 and 120
     or p_requested_count not between 1 and 10
     or jsonb_typeof(coalesce(p_input_context,'{}'::jsonb)) <> 'object'
     or octet_length(coalesce(p_input_context,'{}'::jsonb)::text) > 16000 then
    raise exception 'INVALID_AI_GENERATION_REQUEST' using errcode='22023';
  end if;
  if not exists(
    select 1
    from public.quiz_versions qv
    join public.quizzes q on q.id=qv.quiz_id
    where qv.id=p_quiz_version_id
      and qv.status='draft'::public.content_version_status
      and q.instructor_id=(select auth.uid())
      and q.archived_at is null
  ) then
    raise exception 'QUIZ_VERSION_SCOPE_OR_STATE_DENIED' using errcode='42501';
  end if;

  insert into public.ai_quiz_generations(
    instructor_id,quiz_version_id,provider,model,input_context,requested_count
  ) values (
    (select auth.uid()),p_quiz_version_id,'openrouter',btrim(p_model),
    coalesce(p_input_context,'{}'::jsonb),p_requested_count
  ) returning * into v_generation;

  perform private.write_audit_event(
    'quiz.ai_draft.requested',
    'ai_quiz_generation',
    v_generation.id,
    null,
    jsonb_build_object(
      'quiz_version_id',p_quiz_version_id,
      'provider','openrouter',
      'model',v_generation.model,
      'requested_count',p_requested_count
    )
  );
  return v_generation;
end
$$;

revoke all on function public.begin_ai_quiz_generation(uuid,text,text,jsonb,integer) from public,anon;
grant execute on function public.begin_ai_quiz_generation(uuid,text,text,jsonb,integer) to authenticated;

commit;
