-- ===================================================================
--  LocWeb Dashboard — socle
--
--  A executer UNE FOIS dans l'editeur SQL Supabase du projet
--  "locweb-clients". Tout est idempotent : relancer le fichier ne
--  casse rien et ne duplique rien.
--
--  Principe directeur : ne RIEN changer a ce que lisent les sites
--  clients deja en ligne. La colonne `valeur` de contenu_site reste
--  la valeur publiee ; le brouillon vit a cote. Aucun redeploiement
--  des quatre sites en production n'est necessaire.
-- ===================================================================


-- -------------------------------------------------------------------
--  1. Le role operateur
--
--  Aujourd'hui les policies filtrent par auth_user_id : un compte ne
--  voit que SON client. C'est exactement ce qu'on veut pour le client,
--  mais ca rend la console impossible — il faut un compte qui voit
--  tout le monde.
--
--  On n'ajoute pas de "super pouvoir" au niveau de la cle : la cle
--  anon reste publique et RLS reste la barriere. On ajoute une table
--  d'operateurs et des policies supplementaires. Les policies etant
--  cumulatives (OR), les regles client existantes ne bougent pas.
-- -------------------------------------------------------------------

create table if not exists operateurs (
  auth_user_id  uuid primary key references auth.users(id) on delete cascade,
  nom           text,
  date_creation timestamptz not null default now()
);

alter table operateurs enable row level security;

-- Un operateur peut lire sa propre ligne (pour que la console sache
-- qui elle a en face). Personne d'autre ne lit cette table.
drop policy if exists "Operateur lit sa propre ligne" on operateurs;
create policy "Operateur lit sa propre ligne"
  on operateurs for select
  using (auth_user_id = auth.uid());

-- security definer : la fonction doit pouvoir lire `operateurs` meme
-- quand l'appelant n'y a pas acces. search_path fige pour eviter
-- qu'un schema temporaire vienne se substituer a public.
create or replace function est_operateur()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from operateurs where auth_user_id = auth.uid());
$$;

revoke all on function est_operateur() from public;
grant execute on function est_operateur() to authenticated;


-- -------------------------------------------------------------------
--  1bis. La table `leads`
--
--  Prevue par `supabase/create_leads_table.sql` mais jamais executee
--  sur la base reelle (constate le 2026-08-22 : "relation leads does
--  not exist"). Reprise ici a l'identique pour que ce fichier soit
--  autonome — le repeter dans les deux fichiers ne pose pas de
--  probleme puisque tout est `if not exists`.
-- -------------------------------------------------------------------

create table if not exists leads (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id),
  nom text,
  email text,
  message text,
  date_creation timestamptz not null default now()
);

-- Les `leads-form.js` ne sont pas identiques d'un site client a l'autre
-- (verifie dans le depot : Azrow envoie aussi `telephone`/`profil`,
-- dimitri-mateus-paysagiste envoie `telephone`/`ville`/`besoin`). Comme
-- la table n'existait pas du tout jusqu'ici, AUCUN de ces formulaires
-- n'a jamais pu ecrire une ligne — PostgREST rejette un insert qui
-- contient une colonne absente. On ajoute donc toutes les colonnes
-- reellement envoyees quelque part dans le depot, pour que chaque site
-- client se mette a fonctionner sans qu'il faille toucher a son JS.
alter table leads add column if not exists telephone text;
alter table leads add column if not exists ville     text;
alter table leads add column if not exists besoin    text;
alter table leads add column if not exists profil    text;

alter table leads enable row level security;

drop policy if exists "Insertion publique de leads" on leads;
create policy "Insertion publique de leads"
  on leads for insert
  to anon
  with check (true);

drop policy if exists "Lecture des leads par leur proprietaire" on leads;
create policy "Lecture des leads par leur proprietaire"
  on leads for select
  using (
    client_id = (select id from clients where auth_user_id = auth.uid())
  );


-- -------------------------------------------------------------------
--  2. Ce que l'operateur a le droit de faire
--
--  Une policy par table et par action. Volontairement explicite
--  plutot que generique : quand il faudra retirer un droit, on saura
--  exactement quelle ligne supprimer.
-- -------------------------------------------------------------------

drop policy if exists "Operateur lit tous les clients" on clients;
create policy "Operateur lit tous les clients"
  on clients for select using (est_operateur());

drop policy if exists "Operateur modifie tous les clients" on clients;
create policy "Operateur modifie tous les clients"
  on clients for update using (est_operateur()) with check (est_operateur());

drop policy if exists "Operateur cree des clients" on clients;
create policy "Operateur cree des clients"
  on clients for insert with check (est_operateur());

drop policy if exists "Operateur lit tout le contenu" on contenu_site;
create policy "Operateur lit tout le contenu"
  on contenu_site for select using (est_operateur());

drop policy if exists "Operateur modifie tout le contenu" on contenu_site;
create policy "Operateur modifie tout le contenu"
  on contenu_site for update using (est_operateur()) with check (est_operateur());

drop policy if exists "Operateur cree du contenu" on contenu_site;
create policy "Operateur cree du contenu"
  on contenu_site for insert with check (est_operateur());

drop policy if exists "Operateur supprime du contenu" on contenu_site;
create policy "Operateur supprime du contenu"
  on contenu_site for delete using (est_operateur());

drop policy if exists "Operateur lit toutes les demandes" on leads;
create policy "Operateur lit toutes les demandes"
  on leads for select using (est_operateur());

drop policy if exists "Operateur modifie toutes les demandes" on leads;
create policy "Operateur modifie toutes les demandes"
  on leads for update using (est_operateur()) with check (est_operateur());


-- -------------------------------------------------------------------
--  3. La fiche client
--
--  `clients` ne portait que le strict minimum. La console a besoin de
--  savoir le metier (pour proposer les bons mots-cles), la ville (pour
--  les decliner), l'adresse du site (pour l'ouvrir en un clic) et
--  l'etat de l'abonnement.
--
--  add column if not exists : la table existe deja en production, on
--  ne la recree pas.
-- -------------------------------------------------------------------

alter table clients add column if not exists metier            text;
alter table clients add column if not exists ville             text;
alter table clients add column if not exists code_postal       text;
alter table clients add column if not exists telephone         text;
alter table clients add column if not exists email             text;
-- (l'adresse du site vit deja dans la colonne `domaine`, on ne la double pas)
alter table clients add column if not exists formule           text;
alter table clients add column if not exists tarif_mensuel     numeric(8,2);
alter table clients add column if not exists date_mise_en_ligne date;
alter table clients add column if not exists statut            text default 'actif';
alter table clients add column if not exists notes             text;

-- Ce que le client a le droit de toucher lui-meme, decide par
-- verticale et pas champ par champ : un restaurant gere sa carte,
-- un plombier n'a pas de carte a gerer.
--   'aucun'    : le client ne touche a rien
--   'essentiel': horaires, coordonnees, bandeau d'annonce
--   'complet'  : essentiel + produits/carte et leurs prix
alter table clients add column if not exists acces_client text default 'essentiel';

alter table clients drop constraint if exists clients_statut_valide;
alter table clients add  constraint clients_statut_valide
  check (statut in ('prospect', 'en_construction', 'actif', 'suspendu', 'resilie'));

alter table clients drop constraint if exists clients_acces_valide;
alter table clients add  constraint clients_acces_valide
  check (acces_client in ('aucun', 'essentiel', 'complet'));


-- -------------------------------------------------------------------
--  4. Brouillon et publication
--
--  Le probleme reel : aujourd'hui toute modification part en direct
--  sur le site du client. Une faute de frappe est publique dans la
--  seconde.
--
--  La solution la moins invasive : `valeur` continue de designer ce
--  qui est EN LIGNE — les sites clients lisent cette colonne et n'ont
--  donc aucune raison de changer. Le brouillon vit dans une colonne
--  separee. Publier, c'est recopier l'un dans l'autre.
--
--  Corollaire : une ligne dont `valeur_brouillon` est NULL n'a aucune
--  modification en attente. La detection est donc gratuite.
-- -------------------------------------------------------------------

alter table contenu_site add column if not exists valeur_brouillon text;
alter table contenu_site add column if not exists date_maj         timestamptz;
alter table contenu_site add column if not exists modifie_par      text;

create index if not exists idx_contenu_brouillon
  on contenu_site (client_id)
  where valeur_brouillon is not null;

-- Publier tout ce qui est en attente pour un client, en une seule
-- transaction : soit la page entiere passe en ligne, soit rien. On
-- evite l'etat intermediaire ou un titre est publie mais pas le
-- sous-titre qui va avec.
create or replace function publier_client(p_client_id uuid)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  n integer;
begin
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


-- -------------------------------------------------------------------
--  5. Le suivi des demandes
--
--  Les demandes arrivent deja dans `leads` (les sites branches y
--  ecrivent via leads-form.js) et un mail part chez le client. Ce
--  qui manque, c'est de savoir ce qu'elles sont devenues — sans quoi
--  impossible de dire au client ce que son site lui a rapporte.
-- -------------------------------------------------------------------

alter table leads add column if not exists statut       text default 'nouvelle';
alter table leads add column if not exists page_origine text;
alter table leads add column if not exists note_interne text;
alter table leads add column if not exists date_traitement timestamptz;

alter table leads drop constraint if exists leads_statut_valide;
alter table leads add  constraint leads_statut_valide
  check (statut in ('nouvelle', 'vue', 'devis_envoye', 'gagnee', 'perdue', 'indesirable'));

create index if not exists idx_leads_client_date on leads (client_id, date_creation desc);


-- -------------------------------------------------------------------
--  6. Le journal de visites
--
--  Pas de Google Analytics, pas de cookie, pas d'adresse IP : on
--  n'enregistre que la page, d'ou vient le visiteur et le type
--  d'appareil. Consequence directe et voulue : aucun bandeau de
--  consentement n'est necessaire sur les sites clients, ce qui est un
--  argument commercial en soi.
--
--  Volume : quelques centaines de lignes par mois et par site. Le
--  jour ou ca devient trop lourd, une vue materialisee par jour
--  suffira — pas avant.
-- -------------------------------------------------------------------

create table if not exists visites (
  id          bigserial primary key,
  client_id   uuid not null references clients(id) on delete cascade,
  chemin      text,
  referent    text,
  appareil    text,
  horodatage  timestamptz not null default now()
);

create index if not exists idx_visites_client_date on visites (client_id, horodatage desc);

alter table visites enable row level security;

-- Ecriture anonyme : c'est le visiteur du site client qui insere.
drop policy if exists "Enregistrement anonyme d une visite" on visites;
create policy "Enregistrement anonyme d une visite"
  on visites for insert to anon with check (true);

drop policy if exists "Operateur lit toutes les visites" on visites;
create policy "Operateur lit toutes les visites"
  on visites for select using (est_operateur());

drop policy if exists "Client lit ses visites" on visites;
create policy "Client lit ses visites"
  on visites for select
  using (client_id = (select id from clients where auth_user_id = auth.uid()));


-- -------------------------------------------------------------------
--  7. Les campagnes publicitaires
--
--  La console est le guichet et le tableau des resultats ; la
--  construction des campagnes se fait dans Google Ads. Ce qu'on
--  stocke ici, c'est la demande, le cadrage et le suivi — pas la
--  campagne elle-meme.
--
--  Aucune cle d'API client n'est stockee. L'acces passera par un
--  compte administrateur Google Ads (MCC) : le client accepte une
--  invitation une fois, sa carte reste sur son propre compte.
-- -------------------------------------------------------------------

create table if not exists campagnes (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid not null references clients(id) on delete cascade,
  nom             text not null,
  statut          text not null default 'demandee',
  objectif        text,
  budget_mensuel  numeric(8,2),
  zone            text,
  mots_cles       text[],
  note            text,
  id_google_ads   text,
  date_creation   timestamptz not null default now(),
  date_maj        timestamptz
);

alter table campagnes drop constraint if exists campagnes_statut_valide;
alter table campagnes add  constraint campagnes_statut_valide
  check (statut in ('demandee', 'en_preparation', 'active', 'en_pause', 'terminee'));

create index if not exists idx_campagnes_client on campagnes (client_id, date_creation desc);

alter table campagnes enable row level security;

drop policy if exists "Operateur gere toutes les campagnes" on campagnes;
create policy "Operateur gere toutes les campagnes"
  on campagnes for all using (est_operateur()) with check (est_operateur());

drop policy if exists "Client lit ses campagnes" on campagnes;
create policy "Client lit ses campagnes"
  on campagnes for select
  using (client_id = (select id from clients where auth_user_id = auth.uid()));


-- -------------------------------------------------------------------
--  8. Le profil rempli par le client
--
--  Rempli APRES la livraison : le client complete ses informations et
--  branche ses comptes. Une ligne par client, une colonne par
--  raccordement, avec la date a laquelle il a ete confirme.
--
--  On ne stocke jamais un mot de passe ni une cle. Ces colonnes ne
--  disent que "l'acces a ete accorde, tel jour".
-- -------------------------------------------------------------------

create table if not exists profils_client (
  client_id             uuid primary key references clients(id) on delete cascade,
  horaires              jsonb,
  zone_intervention     text,
  reseaux               jsonb,
  google_business_url   text,
  google_ads_id         text,
  acces_google_business timestamptz,
  acces_google_ads      timestamptz,
  acces_search_console  timestamptz,
  complete_le           timestamptz,
  date_maj              timestamptz not null default now()
);

alter table profils_client enable row level security;

drop policy if exists "Operateur gere tous les profils" on profils_client;
create policy "Operateur gere tous les profils"
  on profils_client for all using (est_operateur()) with check (est_operateur());

drop policy if exists "Client gere son profil" on profils_client;
create policy "Client gere son profil"
  on profils_client for all
  using (client_id = (select id from clients where auth_user_id = auth.uid()))
  with check (client_id = (select id from clients where auth_user_id = auth.uid()));


-- ===================================================================
--  DERNIERE ETAPE, A FAIRE A LA MAIN
--
--  Se declarer operateur. Remplacer l'adresse ci-dessous par celle du
--  compte Supabase avec lequel on se connectera a la console :
--
--    insert into operateurs (auth_user_id, nom)
--    select id, 'Nicolas' from auth.users
--    where email = 'masia.nicolas.07@gmail.com'
--    on conflict (auth_user_id) do nothing;
--
--  Verification :  select * from operateurs;   -- doit montrer la ligne
--
--  (Pas `select est_operateur()` ici : l'editeur SQL Supabase execute
--  en tant que role admin, pas en tant que toi connecte — auth.uid()
--  y est toujours vide. Le vrai test, c'est de se connecter dans la
--  console : si l'accueil affiche la liste des clients, c'est bon.)
-- ===================================================================
