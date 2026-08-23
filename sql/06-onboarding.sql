-- ===================================================================
--  Onboarding client en 5 etapes (premiere connexion).
--  A executer apres les fichiers 01 a 05.
-- ===================================================================

-- Etape 1 — Votre entreprise
alter table profils_client add column if not exists secteur            text;
alter table profils_client add column if not exists metier_precis      text;
alter table profils_client add column if not exists localisation       text;
-- (zone_intervention existe deja depuis 01-socle.sql)

-- Etape 2 — Votre activite
alter table profils_client add column if not exists nb_employes        integer;
alter table profils_client add column if not exists clients_par_mois   integer;
alter table profils_client add column if not exists panier_moyen       numeric(10,2);
alter table profils_client add column if not exists ca_mensuel         numeric(12,2);
alter table profils_client add column if not exists objectif_ca        numeric(12,2);

-- Etape 3 — Presence en ligne
alter table profils_client add column if not exists site_internet      text;
-- (reseaux, google_business_url, acces_ga4 existent deja)

-- Etape 4 — Objectifs (liste de cles : appels, devis, rdv, trafic, avis)
alter table profils_client add column if not exists objectifs          text[];

-- Etape 5 — Acquisition
alter table profils_client add column if not exists deja_fait_pub      boolean;
alter table profils_client add column if not exists budget_pub_mensuel numeric(10,2);
alter table profils_client add column if not exists utilise_google_ads boolean;
alter table profils_client add column if not exists utilise_meta_ads   boolean;
