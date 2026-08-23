-- ===================================================================
--  08 — Ce dont l'espace client a besoin pour enregistrer quelque chose.
--
--  A executer apres 01 a 07. Idempotent : relancable sans risque.
--
--  Contexte : le fichier 06-onboarding.sql n'a jamais ete passe en
--  production. Comme majProfilTolerant() retire silencieusement chaque
--  colonne absente pour que la requete finisse par passer, l'app
--  affichait "Enregistre" alors que RIEN n'etait ecrit a part
--  complete_le. Ce fichier remet a plat les colonnes reellement
--  utilisees par le code d'aujourd'hui.
--
--  On ne reprend PAS les colonnes de 06 sur le chiffre d'affaires
--  (ca_mensuel, panier_moyen, objectif_ca, nb_employes...) : les
--  questions correspondantes ont ete retirees du questionnaire.
-- ===================================================================


-- -------------------------------------------------------------------
--  1. Questionnaire d'accueil (vue-onboarding.js)
-- -------------------------------------------------------------------

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


-- -------------------------------------------------------------------
--  4. Verification
-- -------------------------------------------------------------------
--  Doit renvoyer 10 lignes. Si une manque, l'app fera semblant
--  d'enregistrer ce champ sans jamais le conserver.

select column_name
from information_schema.columns
where table_name = 'profils_client'
  and column_name in (
    'metier_precis', 'localisation', 'objectifs', 'canaux_actuels',
    'contact_prenom', 'contact_nom', 'contact_email', 'contact_telephone',
    'zone_intervention', 'reseaux')
order by column_name;
