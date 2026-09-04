-- ===================================================================
--  KSM Burger — refonte du site autour de la seule prise de commande
--  A passer APRES la mise en ligne du nouveau site.
--
--  Renumerote de 18 en 20 le 2026-09-04 : deux migrations portaient le
--  numero 18, ce qui rendait impossible de savoir laquelle avait ete
--  passee. Le contenu n'a pas bouge.
--
--  Pourquoi ce fichier existe : le contenu des zones balisees vit en
--  base, pas dans le HTML. Tant que ces lignes ne bougent pas, le
--  nouveau site affiche l'ancien discours — l'espace client gagne
--  toujours contre le fichier deploye, et c'est voulu.
-- ===================================================================

-- 1. Le titre du hero -----------------------------------------------
--    L'ancien annoncait le produit (« Burgers Faits Maison »). Le
--    nouveau annonce l'action, parce que c'est le seul but du site.
--    Kassim reste libre de le rechanger depuis son espace.
update contenu_site set valeur = 'Commandez en ligne,'
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and cle_bloc = 'hero_titre_ligne1';

update contenu_site set valeur = 'récupérez sur place.'
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and cle_bloc = 'hero_titre_accent';

update contenu_site set valeur = 'Viande hachée fraîche, frites coupées sur place, burgers nommés d''après les crus du Beaujolais. Vous commandez, on prépare, vous passez la chercher.'
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and cle_bloc = 'hero_sous_titre';

update contenu_site set valeur = 'Le fast-food artisanal du Beaujolais. Burgers frais, faits maison, nommés d''après les crus locaux. Commande à emporter, à récupérer sur place.'
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and cle_bloc = 'footer_description';

-- Le lundi etait saisi « Ferme » sans accent.
update contenu_site set valeur = 'Fermé'
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and cle_bloc = 'horaires_lundi';


-- 2. Les zones devenues orphelines -----------------------------------
--    Les sections A propos, Pourquoi, Temoignages, Chiffres et FAQ
--    n'existent plus sur le site. Leurs lignes, elles, restent en
--    base : l'espace client liste ce qu'il trouve dans `contenu_site`,
--    pas ce qu'il trouve dans la page. Sans ce menage, Kassim voit
--    dans « Mon site » des textes qu'il peut modifier et qui ne
--    s'afficheront jamais nulle part.
--
--    `pourquoi_%` est le cas le plus genant : le manifeste le range
--    dans le groupe « Services », l'un des trois seuls groupes
--    affiches a un restaurateur.
--
--    A verifier avant, si tu veux voir ce qui part :
--      select cle_bloc, valeur from contenu_site
--       where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
--         and (cle_bloc like 'apropos%' or cle_bloc like 'pourquoi%'
--           or cle_bloc like 'temoin%'  or cle_bloc like 'stat%'
--           or cle_bloc like 'faq%');
delete from contenu_site
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and (cle_bloc like 'apropos%'
     or cle_bloc like 'pourquoi%'
     or cle_bloc like 'temoin%'
     or cle_bloc like 'stat%'
     or cle_bloc like 'faq%');


-- 3. Verification ----------------------------------------------------
--    Doit ramener exactement les 11 zones du nouveau site :
--    hero x3, horaires x7, footer_description.
select cle_bloc, valeur
  from contenu_site
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
 order by cle_bloc;
