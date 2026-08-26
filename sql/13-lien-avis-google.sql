-- ===================================================================
--  13 — Le lien pour demander un avis Google.
--
--  A executer apres 12.
--
--  Les avis sont le premier levier de referencement local d'un
--  artisan, et personne n'en demande — parce qu'il faut retrouver le
--  bon lien dans son compte Google au moment ou on l'a en face de soi,
--  c'est-a-dire jamais.
--
--  Avec cette colonne, le lien est enregistre une fois et l'espace en
--  fait un QR code : le client le montre sur son telephone en fin de
--  chantier, l'autre le scanne, et le formulaire d'avis s'ouvre
--  directement.
--
--  Il se saisit a la main pour l'instant. L'API Fiche Google le
--  renvoie dans `metadata.newReviewUri` — des que l'acces est accorde
--  (demande deposee le 2026-08-23), le remplissage deviendra
--  automatique, comme celui de l'identifiant GA4.
-- ===================================================================

alter table profils_client
  add column if not exists lien_avis_google text;

comment on column profils_client.lien_avis_google is
  'Lien court « demander un avis » de la fiche Google, du type https://g.page/r/XXXX/review. Saisi a la main tant que l API Fiche Google n est pas accessible.';


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------

select client_id, lien_avis_google from profils_client;
