-- The hourly reminder job read current_setting('app.settings.service_role_key'),
-- which Supabase no longer provides, so every run since 2026-02-03 failed.
-- It now sends the public anon key (stored in Vault as reeflynk_anon_key,
-- created separately so the key isn't in git) to satisfy verify_jwt; the
-- function itself is still gated by X-Cron-Secret.
select cron.alter_job(1, command := $cmd$SELECT net.http_post(url := 'https://ueeqgqqthiwcrvopdkft.supabase.co/functions/v1/send-maintenance-email', headers := jsonb_build_object('Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'reeflynk_anon_key'), 'X-Cron-Secret', (select decrypted_secret from vault.decrypted_secrets where name = 'reeflynk_cron_secret')), body := '{}'::jsonb);$cmd$);
