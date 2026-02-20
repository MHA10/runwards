-- Function to get weekly leaderboard
-- Security Definer to bypass RLS on step_logs for aggregation
create or replace function get_weekly_leaderboard(city_filter text default null)
returns table (
  user_id uuid,
  display_name text,
  city text,
  weekly_steps bigint,
  rank bigint
) 
language sql
security definer
as $$
  select 
    u.id, 
    u.display_name, 
    u.city, 
    sum(s.steps) as weekly_steps,
    rank() over (order by sum(s.steps) desc) as rank
  from users u
  join step_logs s on u.id = s.user_id
  where s.date >= date_trunc('week', current_date)
  and (city_filter is null or u.city = city_filter)
  group by u.id
  order by weekly_steps desc
  limit 50;
$$;
