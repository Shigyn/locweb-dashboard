-- ===================================================================
--  LocWeb Dashboard — historique des publications
--
--  A executer UNE FOIS, apres 01-socle.sql, dans le meme editeur SQL
--  Supabase. Idempotent comme le reste.
--
--  Demande du cahier des charges (dashboard-locweb/SKILL.md, module
--  "Mon site") : "Historique des modifications visible (date +
--  description du changement)". Une ligne par CHAMP publie (pas par
--  clic sur "Publier") : si quelqu'un publie cinq champs d'un coup, ca
--  fait cinq lignes d'historique, chacune avec son avant/apres — plus
--  utile qu'une seule ligne "5 modifications" qui ne dit pas lesquelles.
-- ===================================================================

create table if not exists historique_publications (
  id                bigserial primary key,
  client_id         uuid not null references clients(id) on delete cascade,
  cle_bloc          text not null,
  ancienne_valeur   text,
  nouvelle_valeur   text,
  publie_par        text not null default 'operateur',
  date_publication  timestamptz not null default now()
);

alter table historique_publications drop constraint if exists historique_publie_par_valide;
alter table historique_publications add  constraint historique_publie_par_valide
  check (publie_par in ('operateur', 'client'));

create index if not exists idx_historique_client_date
  on historique_publications (client_id, date_publication desc);

alter table historique_publications enable row level security;

drop policy if exists "Operateur lit tout l historique" on historique_publications;
create policy "Operateur lit tout l historique"
  on historique_publications for select using (est_operateur());

drop policy if exists "Operateur ecrit l historique" on historique_publications;
create policy "Operateur ecrit l historique"
  on historique_publications for insert with check (est_operateur());

drop policy if exists "Client lit son historique" on historique_publications;
create policy "Client lit son historique"
  on historique_publications for select
  using (client_id = (select id from clients where auth_user_id = auth.uid()));

drop policy if exists "Client ecrit son historique" on historique_publications;
create policy "Client ecrit son historique"
  on historique_publications for insert
  with check (client_id = (select id from clients where auth_user_id = auth.uid()));


-- -------------------------------------------------------------------
--  publier_client() logue desormais chaque champ avant de l'ecraser,
--  dans la MEME transaction que la publication elle-meme : soit les
--  deux reussissent ensemble, soit aucune des deux ne laisse de trace
--  partielle.
--
--  Cote portail client, la publication ne passe PAS par cette fonction
--  (elle publierait aussi un brouillon operateur en cours sur une
--  section que le client ne voit meme pas — voir admin.js). Le portail
--  client insere donc ses propres lignes d'historique directement,
--  avec publie_par = 'client'.
-- -------------------------------------------------------------------

create or replace function publier_client(p_client_id uuid)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  n integer;
begin
  insert into historique_publications (client_id, cle_bloc, ancienne_valeur, nouvelle_valeur, publie_par)
  select client_id, cle_bloc, valeur, valeur_brouillon, 'operateur'
  from contenu_site
  where client_id = p_client_id
    and valeur_brouillon is not null;

  update contenu_site
     set valeur           = valeur_brouillon,
         valeur_brouillon = null,
         date_maj         = now()
   where client_id = p_client_id
     and valeur_brouillon is not null;

  get diagnostics n = row_count;
  return n;
end;
$$;

grant execute on function publier_client(uuid) to authenticated;
