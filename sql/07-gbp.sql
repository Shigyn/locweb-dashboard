-- ===================================================================
--  Google Business Profile — colonne de cache du compte proprietaire.
--  A executer apres les fichiers 01 a 06.
-- ===================================================================

-- L'API des avis exige le nom du compte Google proprietaire de la fiche
-- (format "accounts/123456"), en plus de l'identifiant de fiche. On le
-- retrouve une fois au premier appel puis on le garde ici, pour eviter
-- une requete supplementaire a chaque chargement de page.
alter table connexions_google add column if not exists compte_google text;
