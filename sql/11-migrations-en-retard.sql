-- ===================================================================
--  LocWeb — les trois migrations en attente, en un bloc.
--
--  A coller d'un seul tenant dans le SQL Editor Supabase.
--  Idempotent : relancable sans risque.
--
--  Constate le 2026-08-23 : 02, 08 et 10 n'avaient jamais ete passees.
--  Consequences visibles dans l'app — l'historique des publications ne
--  s'affichait pour personne, les reponses au questionnaire n'etaient
--  pas conservees, et le bouton "Envoyer ma demande" de campagne
--  echouait pour tout le monde.
-- ===================================================================

-- ==================================================================
--  02 — historique des publications
-- ==================================================================

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

-- ==================================================================
--  08 — colonnes du questionnaire, Mes infos, parrainage
-- ==================================================================

-- -------------------------------------------------------------------
--  1. Questionnaire d'accueil (vue-onboarding.js)
-- -------------------------------------------------------------------

-- Grande famille choisie en carte a l'etape 1 : artisan, independant,
-- restaurateur, autre. Sert a trier vite ; metier_precis donne le detail.
alter table profils_client add column if not exists secteur        text;

-- Metier et ville tels que le CLIENT les decrit. Volontairement
-- distincts de clients.metier / clients.ville, qui sont les champs de
-- l'operateur : les deux peuvent legitimement differer, et ecraser la
-- fiche operateur avec une saisie client serait une mauvaise surprise.
alter table profils_client add column if not exists metier_precis  text;
alter table profils_client add column if not exists localisation   text;

-- Listes a choix multiple. text[] plutot que jsonb : ce sont des
-- listes plates de cles, et un text[] se filtre directement en SQL.
alter table profils_client add column if not exists objectifs      text[];
alter table profils_client add column if not exists canaux_actuels text[];

-- (zone_intervention et reseaux existent depuis 01-socle.sql)


-- -------------------------------------------------------------------
--  2. Mes infos (vue-mes-infos.js)
-- -------------------------------------------------------------------

-- Qui joindre quand le site tombe. Distinct de clients.email /
-- clients.telephone, qui sont les coordonnees de facturation.
alter table profils_client add column if not exists contact_prenom    text;
alter table profils_client add column if not exists contact_nom       text;
alter table profils_client add column if not exists contact_email     text;
alter table profils_client add column if not exists contact_telephone text;


-- -------------------------------------------------------------------
--  3. Parrainage (vue-parrainage.js)
-- -------------------------------------------------------------------

create table if not exists parrainages (
  id                uuid primary key default gen_random_uuid(),
  parrain_client_id uuid not null references clients(id) on delete cascade,
  filleul_client_id uuid references clients(id) on delete set null,
  filleul_nom       text,
  code_utilise      text,
  -- 'en_attente' tant que le filleul n'a pas signe, 'valide' une fois
  -- le mois offert applique, 'annule' si ca ne se fait pas.
  statut            text not null default 'en_attente',
  date_creation     timestamptz not null default now(),
  date_validation   timestamptz
);

create index if not exists parrainages_parrain_idx
  on parrainages (parrain_client_id, date_creation desc);

alter table parrainages enable row level security;

drop policy if exists "Operateur gere les parrainages" on parrainages;
create policy "Operateur gere les parrainages"
  on parrainages for all using (est_operateur()) with check (est_operateur());

-- Le client LIT ses parrainages, il ne les cree pas : c'est l'operateur
-- qui enregistre un filleul quand il signe. Sans ca, n'importe qui
-- pourrait s'inventer des mois offerts.
drop policy if exists "Client lit ses parrainages" on parrainages;
create policy "Client lit ses parrainages"
  on parrainages for select
  using (parrain_client_id = (select id from clients where auth_user_id = auth.uid()));

-- Code de parrainage fige. Tant qu'il est nul, l'app en derive un
-- depuis le nom du site ; le remplir ici permet de le figer si le nom
-- du site change.
alter table clients add column if not exists code_parrainage text;
create unique index if not exists clients_code_parrainage_idx
  on clients (code_parrainage) where code_parrainage is not null;

-- ==================================================================
--  10 — le client peut demander une campagne
-- ==================================================================

-- Le client cree la demande, il ne cree pas la campagne. Le `with check`
-- verrouille deux choses a la fois :
--   - la ligne lui appartient ;
--   - le statut part obligatoirement a 'demandee'.
-- Sans la seconde condition, un client pourrait inserer une campagne
-- deja "en cours" et fausser le suivi de Nico.
drop policy if exists "Client demande une campagne" on campagnes;
create policy "Client demande une campagne"
  on campagnes for insert
  with check (
    client_id = (select id from clients where auth_user_id = auth.uid())
    and statut = 'demandee'
  );

-- Volontairement PAS de policy d'UPDATE ni de DELETE pour le client :
-- une fois la demande partie, elle appartient au suivi. Un client qui
-- veut changer son budget refait une demande ou nous appelle.


-- -------------------------------------------------------------------


-- ===================================================================
--  Verification finale
-- ===================================================================
--  Trois lignes attendues : les trois tables existent desormais.
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('historique_publications', 'parrainages', 'profils_client')
order by table_name;
