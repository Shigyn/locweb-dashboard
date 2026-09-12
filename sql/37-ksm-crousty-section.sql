-- ===================================================================
--  KSM : le KSM Crousty devient une section a part entiere.
--
--  Demande de Nicolas le 2026-09-12. Le Crousty etait range dans
--  « Tacos ». Le site est deja pret : `carte.js` le place juste apres
--  les burgers des que sa categorie s'appelle « KSM Crousty », et sa
--  fiche garde son choix de sauce, la formule menu et les supplements.
--
--  Ce fichier ne fait que changer la categorie. La categorie est un
--  champ libre dans l'espace client : Kassim aurait pu le faire
--  lui-meme, et « KSM Crousty » lui sera desormais propose dans la
--  liste.
--
--  A JOUER EN TROIS TEMPS : AVANT, la modification, APRES.
-- ===================================================================

-- AVANT. Deux lignes attendues :
--   « KSM Crousty »  categorie Tacos, avec sa description  -> celle qu'on deplace
--   « KSM CROUSTY »  sans categorie, sans description      -> un brouillon, voir plus bas
select id, nom, categorie, prix, disponible, left(description, 40) as description
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and nom ilike '%crousty%';

-- LA MODIFICATION. Uniquement la fiche complete, celle des Tacos.
update produits
set categorie = 'KSM Crousty'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and nom ilike 'ksm crousty'
  and categorie = 'Tacos';

-- APRES. La fiche complete doit afficher « KSM Crousty ».
select id, nom, categorie, prix
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and nom ilike '%crousty%';

-- -------------------------------------------------------------------
--  LES BROUILLONS : on n'y touche pas ici.
--
--  Quatre produits SANS CATEGORIE : « KSM CROUSTY » (vide) et trois
--  « Nouveau produit ». Ils ont ete crees depuis l'espace client — sans
--  doute une tentative de creer la section soi-meme. Ils s'affichaient
--  aux clients dans une section « Autres » ; `carte.js` les ecarte
--  desormais tant qu'ils n'ont pas de categorie.
--
--  Les supprimer est definitif : a faire seulement apres avoir verifie
--  avec Kassim qu'il n'est pas en train de les remplir.
--
-- delete from produits
-- where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
--   and (categorie is null or trim(categorie) = '')
--   and (nom = 'Nouveau produit' or (nom = 'KSM CROUSTY' and description is null));
-- -------------------------------------------------------------------
