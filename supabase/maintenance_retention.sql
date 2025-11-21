-- Rotinas de manutenção e retenção de dados para o marketplace
-- 1) Tabela agregada para preservar métricas históricas em formato enxuto
create extension if not exists pg_cron with schema cron;

create table if not exists public.visualizacoes_diarias (
    anuncio_id text not null,
    dia date not null,
    total_views integer not null,
    unique_viewers integer not null,
    primary key (anuncio_id, dia)
);

-- 2) Função que agrega visualizações mais antigas (antes de hoje) para a tabela enxuta
create or replace function public.aggregate_visualizacoes_antigas()
returns void as $$
begin
    insert into public.visualizacoes_diarias (anuncio_id, dia, total_views, unique_viewers)
    select
        anuncio_id::text,
        date(created_at) as dia,
        count(*)::int as total_views,
        count(distinct viewer_id)::int as unique_viewers
    from public.visualizacoes
    where created_at < date_trunc('day', now())
    group by anuncio_id, date(created_at)
    on conflict (anuncio_id, dia) do update
        set total_views     = excluded.total_views,
            unique_viewers  = excluded.unique_viewers;
end;
$$ language plpgsql security definer;

-- 3) Função que remove visualizações "cruas" com mais de 90 dias (após agregação)
create or replace function public.purge_visualizacoes_antigas()
returns void as $$
begin
    delete from public.visualizacoes
    where created_at < now() - interval '90 days';
end;
$$ language plpgsql security definer;

-- 4) Função que elimina favoritos muito antigos (ex.: mais de 180 dias)
create or replace function public.purge_favoritos_antigos()
returns void as $$
begin
    delete from public.favoritos
    where created_at < now() - interval '180 days';
end;
$$ language plpgsql security definer;

-- 5) Agendamento diário (pg_cron) às 03:30 UTC
do $$
declare
    existing_job_id integer;
begin
    select jobid into existing_job_id from cron.job where jobname = 'triunvirato_agg_visualizacoes';
    if existing_job_id is null then
        perform cron.schedule('triunvirato_agg_visualizacoes', '30 3 * * *', 'select public.aggregate_visualizacoes_antigas();');
    else
        perform cron.alter_job(job_id => existing_job_id, new_schedule => '30 3 * * *', new_command => 'select public.aggregate_visualizacoes_antigas();');
    end if;
    select jobid into existing_job_id from cron.job where jobname = 'triunvirato_purge_visualizacoes';
    if existing_job_id is null then
        perform cron.schedule('triunvirato_purge_visualizacoes', '35 3 * * *', 'select public.purge_visualizacoes_antigas();');
    else
        perform cron.alter_job(job_id => existing_job_id, new_schedule => '35 3 * * *', new_command => 'select public.purge_visualizacoes_antigas();');
    end if;
    select jobid into existing_job_id from cron.job where jobname = 'triunvirato_purge_favoritos';
    if existing_job_id is null then
        perform cron.schedule('triunvirato_purge_favoritos', '40 3 * * *', 'select public.purge_favoritos_antigos();');
    else
        perform cron.alter_job(job_id => existing_job_id, new_schedule => '40 3 * * *', new_command => 'select public.purge_favoritos_antigos();');
    end if;
end;
$$;

-- 6) Relatório rápido de espaço por tabela (executar manualmente quando necessário)
-- select relname,
--        pg_size_pretty(pg_total_relation_size(relid)) as total_size
--   from pg_catalog.pg_statio_user_tables
--  order by pg_total_relation_size(relid) desc;
