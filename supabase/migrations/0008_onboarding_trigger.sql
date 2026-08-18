-- SoloLevelUp — onboarding: on signup, create the profile, seed the three
-- default metrics, start the first Challenge, and snapshot the Day-1 Rise
-- Rating (FR-2.1, FR-5.3). Standard Supabase "create profile on signup"
-- pattern: SECURITY DEFINER so it can write into public.* from a trigger
-- fired on the auth.users table the client doesn't own.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_challenge_id uuid;
  -- Day-1 baseline for all six stats. 44 is a deliberate nod to the
  -- reference video's "+41" deltas (44 + 41 = 85); purely a taste choice,
  -- tune freely (SRS §9, open question 3).
  v_baseline numeric := 44;
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)));

  insert into public.metric_definitions (user_id, key, display_name, unit, aggregation, icon_ref, is_system)
  values
    (new.id, 'water_liters',  'Water drank',        'L',       'sum',   'water_drop', true),
    (new.id, 'pages_read',    'Pages read',         'pages',   'sum',   'book',       true),
    (new.id, 'cold_showers',  'Cold showers taken', 'showers', 'count', 'shower',     true);

  insert into public.challenges (user_id, start_date, length_days, status)
  values (new.id, current_date, 66, 'active')
  returning id into v_challenge_id;

  insert into public.rise_rating_snapshots
    (user_id, challenge_id, lens, overall, wisdom, strength, focus, confidence, discipline)
  values
    (new.id, v_challenge_id, 'day1',    v_baseline, v_baseline, v_baseline, v_baseline, v_baseline, v_baseline),
    (new.id, v_challenge_id, 'current', v_baseline, v_baseline, v_baseline, v_baseline, v_baseline, v_baseline);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
