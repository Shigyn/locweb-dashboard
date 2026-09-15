-- ===================================================================
--  connexions_google.compte_google (2026-09-15).
--
--  gbp-donnees lit et ecrit cette colonne pour garder le nom du compte
--  proprietaire de la fiche (« accounts/123... »), exige par l'API des
--  avis. Elle n'existait pas : la lecture renvoyait undefined, l'ecriture
--  echouait sans bruit, et chaque chargement redemandait la liste des
--  comptes a Google. Avec la colonne, un appel de moins par affichage.
-- ===================================================================

alter table connexions_google add column if not exists compte_google text;
