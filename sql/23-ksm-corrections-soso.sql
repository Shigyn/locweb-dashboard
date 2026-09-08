-- ===================================================================
--  KSM Burger — corrections demandees par Soso le 2026-09-07
--
--  Relevees dans sa conversation WhatsApp. Chaque bloc porte la
--  demande a laquelle il repond, pour qu'on puisse verifier avec lui
--  ligne par ligne.
--
--  A JOUER EN PREMIER : le bloc 1 corrige un prix qui fait perdre de
--  l'argent a chaque commande. Le reste peut attendre, pas lui.
-- ===================================================================

-- -------------------------------------------------------------------
-- 1. LE BACON EST FACTURE 1 € AU LIEU DE 3 €
--
--    « Supplement bacon + 3 euros ( c'est marquer 1 euros ) »
--
--    Pose par la migration 22, ou le bacon avait ete range avec les
--    garnitures a 1 € alors que c'est une viande. Chaque burger avec
--    bacon vendu depuis a perdu 2 €.
-- -------------------------------------------------------------------
update produits
   set prix = 3.00,
       description = 'Tranches de bacon grillees'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie = 'Suppléments'
   and lower(btrim(nom)) = 'bacon';

-- -------------------------------------------------------------------
-- 2. LA SAUCE SUPPLEMENTAIRE PASSE A 0,50 €
--
--    « Sauce supplementaire met 0,50€ »
-- -------------------------------------------------------------------
update produits
   set prix = 0.50
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie = 'Suppléments'
   and lower(btrim(nom)) = 'sauce supplémentaire';

-- -------------------------------------------------------------------
-- 3. LES FROMAGES AU CHOIX
--
--    « Fromage au choix : Raclette, Cheddar, Boursin, Kiri, Chevre »
--
--    Cheddar, raclette et chevre existent deja (migration 22). Il
--    manquait le boursin et le kiri, tous deux au tarif garniture.
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, 'Suppléments', true, null
from (values
  ('Boursin', 1.00),
  ('Kiri',    1.00)
) as v(nom, prix)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
     and p.categorie = 'Suppléments'
);

-- -------------------------------------------------------------------
-- 4. LES VIANDES AU CHOIX
--
--    « Choix des viandes dans les tacos c'est pas bon faut corriger »
--    puis la liste : Kebab, Tenders, cordon bleu, Viande hachee,
--    Escalope, Nuggets, Bacon, Merguez.
--
--    Le bacon est deja pose au bloc 1, on ne le redonne pas ici.
--    Toutes a 3 €, le tarif viande de la migration 22.
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, 3.00, 'Suppléments', true, null
from (values
  ('Kebab'), ('Tenders'), ('Cordon bleu'),
  ('Viande hachée'), ('Escalope'), ('Nuggets'), ('Merguez')
) as v(nom)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
     and p.categorie = 'Suppléments'
);

-- -------------------------------------------------------------------
-- 5. DEUX PLATS ABSENTS DE LA CARTE
--
--    « Le bazooka ( lui aussi il n'est pas dans le menue si tu peux
--      le rajouter stp 19 euros ) »
--    « KSM Crousty ( lui aussi il n'est pas dans la carte il faut le
--      rajouter ) 10 € »
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, v.categorie, true, v.description
from (values
  ('Le Bazooka', 19.00, 'Burgers',
   'Quatre steaks, cheddar fondu, oignons frits, salade, oignons rouges. Le plus gros de la carte.'),
  ('KSM Crousty', 10.00, 'Tacos',
   'Poulet croustillant, riz, sauce fromagere, sauce barbecue, persil. Servi en box.')
) as v(nom, prix, categorie, description)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
);

-- -------------------------------------------------------------------
-- 6. LA BOX A PARTAGER ETAIT INCOMPLETE
--
--    « Box a partager il manque un truc / C'est 4 tenders 4 nuggets
--      4 bouchee camembert 4 jalapenos / 2 canettes »
-- -------------------------------------------------------------------
update produits
   set description = '4 tenders, 4 nuggets, 4 bouchées camembert, 4 jalapeños et 2 canettes'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(nom)) like 'box%partager%';

-- -------------------------------------------------------------------
-- 7. VERIFICATION
--
--    A lire apres coup : le bacon doit afficher 3,00 et la sauce 0,50.
--    Si une ligne manque, c'est que le nom en base differe de celui
--    cherche ici — le `like` du bloc 6 est le plus fragile.
-- -------------------------------------------------------------------
select categorie, nom, prix, disponible
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and (categorie = 'Suppléments'
        or lower(btrim(nom)) in ('le bazooka', 'ksm crousty')
        or lower(btrim(nom)) like 'box%partager%')
 order by categorie, prix desc, nom;
