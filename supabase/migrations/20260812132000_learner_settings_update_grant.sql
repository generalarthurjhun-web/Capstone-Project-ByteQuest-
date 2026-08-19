-- Complete the existing own-row settings policy with the matching table grant.
-- RLS continues to constrain both USING and WITH CHECK to auth.uid().

begin;

grant update (
  notifications_enabled,
  sound_enabled,
  vibration_enabled,
  theme_mode,
  language,
  updated_at
) on public.user_settings to authenticated;

commit;
