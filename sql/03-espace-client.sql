-- ===================================================================
--  LocWeb Dashboard — extensions pour le tableau de bord client complet
--
--  A executer apres 01-socle.sql et 02-historique.sql, dans le meme
--  editeur SQL Supabase. Idempotent.
-- ===================================================================

-- -------------------------------------------------------------------
--  1. Pixels publicitaires — meme principe que google_business_url /
--     google_ads_id : le client colle son propre identifiant, aucune
--     cle secrete n'est jamais demandee ici.
-- -------------------------------------------------------------------

-- Une colonne d'acces PAR plateforme, pas une seule partagee : Meta et
-- Google sont deux connexions independantes, l'affichage de l'une ne doit
-- pas dependre de l'autre.
alter table profils_client add column if not exists pixel_meta_id text;
alter table profils_client add column if not exists acces_pixel_meta timestamptz;
alter table profils_client add column if not exists pixel_google_id text;
alter table profils_client add column if not exists acces_pixel_google timestamptz;


-- -------------------------------------------------------------------
--  2. Le client peut mettre a jour le statut de SES propres demandes
--
--  Jusqu'ici seul l'operateur pouvait faire passer une demande de
--  "nouvelle" a "traitee" etc. Le nouvel onglet "Mon activite" du
--  portail client permet au client de gerer sa propre boite de
--  reception — il lui faut donc le droit d'ecrire, borne a ses
--  propres demandes.
-- -------------------------------------------------------------------

drop policy if exists "Client modifie ses demandes" on leads;
create policy "Client modifie ses demandes"
  on leads for update
  using (client_id = (select id from clients where auth_user_id = auth.uid()))
  with check (client_id = (select id from clients where auth_user_id = auth.uid()));


-- (La lecture de ses propres visites et de ses propres campagnes est deja
-- couverte par des policies posees dans 01-socle.sql — pas besoin de les
-- reposer ici.)


-- -------------------------------------------------------------------
--  3. Le client peut creer une demande de campagne pour lui-meme
--
--  "Acquisition" cote client permet de demander une campagne (sans
--  paiement en ligne pour l'instant — Nico la met en place a la main
--  ensuite, comme deja prevu pour le circuit operateur). Le client ne
--  doit pouvoir creer une campagne QUE pour son propre client_id, et
--  seulement au statut de depart "demandee" — jamais se l'auto-activer.
-- -------------------------------------------------------------------

drop policy if exists "Client demande une campagne" on campagnes;
create policy "Client demande une campagne"
  on campagnes for insert
  with check (
    client_id = (select id from clients where auth_user_id = auth.uid())
    and statut = 'demandee'
  );
