-- View para ranking dos anúncios mais favoritados nos últimos 15 dias
create or replace view public.v_top_favoritos_15d as
select
    f.veiculo_id,
    v.usuario_id,
    v.cidade,
    v.estado,
    coalesce(
      nullif(min(v.titulo) filter (where v.titulo is not null and v.titulo <> ''), ''),
      concat_ws(' ',
        min(v.marca) filter (where v.marca is not null and v.marca <> ''),
        min(v.modelo) filter (where v.modelo is not null and v.modelo <> ''),
        min(v.versao) filter (where v.versao is not null and v.versao <> '')
      )
    ) as titulo,
    (
      case
        when v.fotos is not null and array_length(v.fotos, 1) > 0
        then v.fotos[1]
        else null
      end
    ) as thumbnail,
    count(f.*)::int as total_favoritos,
    min(f.created_at) as primeiro_favorito,
    max(f.created_at) as ultimo_favorito
from public.favoritos f
join public.veiculos v on v.id = f.veiculo_id
where f.created_at >= (now() - interval '15 days')
  and coalesce(v.status, 'ativo') = 'ativo'
group by f.veiculo_id, v.usuario_id, v.cidade, v.estado, thumbnail;

-- Índice auxiliar para acelerar filtros por created_at
create index if not exists favoritos_created_at_idx on public.favoritos (created_at);
