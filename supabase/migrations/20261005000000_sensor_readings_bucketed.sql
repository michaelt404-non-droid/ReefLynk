-- Adaptive chart series: averages a user's readings into ~p_points evenly
-- sized time buckets, so charts stay fast and complete no matter how many
-- readings the reef controller has uploaded (PostgREST caps plain selects at
-- 1000 rows). A bucket holding a single manual entry keeps its exact time.

create index if not exists sensor_readings_user_type_time_idx
  on public.sensor_readings (user_id, sensor_type, created_at desc);

create or replace function public.sensor_readings_bucketed(
  p_sensor_type text,
  p_since timestamptz default null,  -- null = from the first reading
  p_points int default 300
)
returns table (bucket_time timestamptz, value double precision, readings int)
language sql
stable
security invoker
set search_path = public
as $$
  with bounds as (
    select coalesce(p_since, min(created_at)) as since
    from sensor_readings
    where user_id = auth.uid() and sensor_type = p_sensor_type
  ), sized as (
    select since,
           greatest((now() - since) / greatest(p_points, 1), interval '1 minute') as width
    from bounds
    where since is not null
  )
  select to_timestamp(avg(extract(epoch from r.created_at))) as bucket_time,
         avg(r.value)::double precision as value,
         count(*)::int as readings
  from sensor_readings r
  cross join sized s
  where r.user_id = auth.uid()
    and r.sensor_type = p_sensor_type
    and r.created_at >= s.since
  group by date_bin(s.width, r.created_at, s.since)
  order by 1;
$$;

grant execute on function public.sensor_readings_bucketed(text, timestamptz, int) to authenticated;
