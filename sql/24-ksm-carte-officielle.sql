-- ===================================================================
--  KSM Burger — la carte, d'apres les trois cartes officielles
--  envoyees le 2026-09-08.
--
--  Source : la carte paysage noire (burgers, salades, frites), la
--  carte portrait « bowls / snacking / desserts / boissons », et la
--  carte portrait « burgers / tacos / sauces / viandes / fromages ».
--
--  LES CARTES SE CONTREDISENT SUR QUATRE POINTS, listes en fin de
--  fichier. DEUX SONT TRANCHES le 2026-09-08 : pas de livraison, et
--  les horaires restent tels quels (Kassim les modifiera lui-meme
--  depuis l'editeur).
--
--  Les DEUX AUTRES — les fromages et les viandes au choix — attendent
--  encore : la carte imprimee et les messages de Soso ne disent pas la
--  meme chose, et personne n'a tranche.
-- ===================================================================

-- -------------------------------------------------------------------
--  1. LES BURGERS
--     Prix et compositions de la carte paysage, completes par la
--     carte portrait qui detaille davantage (confit d'oignons, sauce).
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, 'Burgers', true, v.description
from (values
  ('Le Moulin à vent',        12.00, 'Poulet pané, salade, oignon rouge, cheddar, sauce'),
  ('Le Beaujolais',           12.00, 'Steak 120g, salade, oignon rouge, bacon, cheddar, sauce'),
  ('Le Fleurie',              12.00, 'Steak 120g, salade, chèvre, miel, confit d''oignons, sauce'),
  ('Le Saint Amour',          12.00, 'Steak végétarien, salade, cheddar, oignons, sauce'),
  ('Le Morgon',               12.00, 'Steak 120g, salade, oignons, bacon, œuf à cheval, cheddar, sauce'),
  ('Le Chiroubles',           12.00, 'Steak 120g, salade, oignons rouges, rösti de pomme de terre, raclette, sauce'),
  ('Le Regnié',                9.00, 'Steak 120g, salade, cheddar'),
  ('Le Filet ô fish',          8.00, 'Filet de colin, salade, cheddar'),
  ('Le Chénas',               14.00, 'Double steak 120g, salade, confit d''oignons rouges, double cheddar, cornichons, sauce'),
  ('Le Juliénas',             14.00, 'Double steak 120g, salade, rösti, double cheddar, oignons, sauce'),
  ('Le Double filet ô fish',  12.00, 'Double filet de colin, salade, cheddar'),
  ('Le Triple cheese bacon',  16.00, 'Triple steak 120g, salade, bacon, cheddar'),
  ('Le Triple juliénas',      17.00, 'Triple steak 120g, salade, rösti, oignons')
) as v(nom, prix, description)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
);

-- Mise a jour des prix et compositions pour les burgers deja en base.
update produits p
   set prix = v.prix, description = v.description, categorie = 'Burgers'
  from (values
  ('Le Moulin à vent',        12.00, 'Poulet pané, salade, oignon rouge, cheddar, sauce'),
  ('Le Beaujolais',           12.00, 'Steak 120g, salade, oignon rouge, bacon, cheddar, sauce'),
  ('Le Fleurie',              12.00, 'Steak 120g, salade, chèvre, miel, confit d''oignons, sauce'),
  ('Le Saint Amour',          12.00, 'Steak végétarien, salade, cheddar, oignons, sauce'),
  ('Le Morgon',               12.00, 'Steak 120g, salade, oignons, bacon, œuf à cheval, cheddar, sauce'),
  ('Le Chiroubles',           12.00, 'Steak 120g, salade, oignons rouges, rösti de pomme de terre, raclette, sauce'),
  ('Le Regnié',                9.00, 'Steak 120g, salade, cheddar'),
  ('Le Filet ô fish',          8.00, 'Filet de colin, salade, cheddar'),
  ('Le Chénas',               14.00, 'Double steak 120g, salade, confit d''oignons rouges, double cheddar, cornichons, sauce'),
  ('Le Juliénas',             14.00, 'Double steak 120g, salade, rösti, double cheddar, oignons, sauce'),
  ('Le Double filet ô fish',  12.00, 'Double filet de colin, salade, cheddar'),
  ('Le Triple cheese bacon',  16.00, 'Triple steak 120g, salade, bacon, cheddar'),
  ('Le Triple juliénas',      17.00, 'Triple steak 120g, salade, rösti, oignons')
) as v(nom, prix, description)
 where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(p.nom)) = lower(v.nom);

-- -------------------------------------------------------------------
--  2. TACOS, BOWLS, SALADES
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, v.categorie, true, v.description
from (values
  ('Tacos simple',        8.00,  'Tacos', '1 viande au choix, crudités, frites, sauce'),
  ('Maxi tacos',         10.00,  'Tacos', '2 viandes au choix, crudités, frites, sauce'),
  ('Bowl',                8.00,  'Bowls', 'Riz, viande au choix, fromage au choix, sauce, frites, oignons frits'),
  ('Salade chèvre chaud',11.90,  'Salades', 'Salade, chèvre chaud, lardons, oignons frits, noix'),
  ('Salade César',       11.90,  'Salades', 'Salade, poulet pané, oignons frits, noix')
) as v(nom, prix, categorie, description)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
);

-- -------------------------------------------------------------------
--  3. FRITES ET SNACKING
--
--  La carte paysage et la carte portrait donnent deux listes de
--  frites qui se recoupent. On garde l'union, avec les prix de la
--  carte portrait qui est la plus complete.
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, v.categorie, true, v.description
from (values
  ('Frites',                  3.00, 'Frites', null),
  ('Frites cheddar',          4.00, 'Frites', null),
  ('Frites gruyère',          4.00, 'Frites', 'Sauce gruyère maison'),
  ('Frites bacon cheddar',    4.50, 'Frites', null),
  ('Frites gruyère bacon',    4.50, 'Frites', 'Sauce gruyère maison et bacon'),
  ('Frites oignons frits',    4.50, 'Frites', null),
  ('Frites jalapeños',        5.00, 'Frites', null),
  ('Jalapeños x6',            5.00, 'Snacking', null),
  ('Nuggets x6',              5.00, 'Snacking', null),
  ('Bouchées camembert x6',   5.00, 'Snacking', null),
  ('Tenders maison x5',       6.00, 'Snacking', 'Tenders faits maison'),
  ('Cheeseburger',            2.50, 'Snacking', null)
) as v(nom, prix, categorie, description)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
);

-- -------------------------------------------------------------------
--  4. DESSERTS, BOISSONS, MENU ENFANT
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, v.categorie, true, v.description
from (values
  ('Tarte Daim',             3.00, 'Desserts', null),
  ('Donut''s',               2.00, 'Desserts', null),
  ('Tiramisu',               3.00, 'Desserts', null),
  ('Confiseries',            1.00, 'Desserts', null),
  ('Milkshake gourmand',     4.50, 'Desserts', 'Oreo, M&M''s ou Bueno'),
  ('Milkshake',              3.50, 'Desserts', 'Vanille, fraise ou chocolat'),
  ('Canette 33cl',           1.50, 'Boissons', null),
  ('Bouteille',              2.00, 'Boissons', null),
  ('Eau 50cl',               1.00, 'Boissons', null),
  ('Menu enfant',            6.00, 'Menu enfant',
   '4 nuggets ou mini burger, frites, Capri-Sun ou eau aromatisée, compote ou Tops')
) as v(nom, prix, categorie, description)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
);

-- -------------------------------------------------------------------
--  5. LES SAUCES
--     Douze sauces, offertes. Elles entrent comme supplements a 0 €
--     pour apparaitre dans la fiche d'un plat sans etre commandables
--     seules — la categorie « Supplements » est masquee de la carte
--     publique par carte.js.
-- -------------------------------------------------------------------
insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, 0.00, 'Suppléments', true, 'Sauce au choix'
from (values
  ('Ketchup'), ('Mayonnaise'), ('Sauce blanche'), ('Tartare'), ('Curry'),
  ('Gruyère maison'), ('Harissa'), ('Moutarde'), ('Samouraï'),
  ('Sauce burger'), ('Barbecue'), ('Algérienne')
) as v(nom)
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
     and p.categorie = 'Suppléments'
);

-- ===================================================================
--  LES QUATRE CONTRADICTIONS, A TRANCHER AVEC KASSIM
--  Rien n'est decide ici. Chaque point cite ses deux sources.
--
--  1. LES HORAIRES — TRANCHE le 2026-09-08 : ON NE TOUCHE A RIEN.
--     Les trois sources se contredisaient (lundi+mardi fermes contre
--     « ferme le jeudi », midi 12h-13h30 contre 11h30-14h). Decision :
--     le site garde ce qu'il affiche, et Kassim corrigera lui-meme
--     depuis l'editeur — les sept lignes portent deja une zone
--     `horaires_*`, il n'a besoin de personne.
--
--     C'est le bon arbitrage : deviner des horaires a la place du
--     restaurateur, c'est envoyer des clients devant une porte close.
--
--  2. LA LIVRAISON — TRANCHE le 2026-09-08 : IL N'Y EN A PAS.
--     La carte portrait annoncait « livraison a partir de 20 € d'achat,
--     environ 15 km ». C'est faux ou perime. Le site reste sur le
--     retrait sur place, et rien n'est a construire.
--
--     A SIGNALER A KASSIM : cette mention figure sur une carte
--     imprimee qui circule. Un client qui la lit appellera pour se
--     faire livrer.
--
--  3. LES FROMAGES SUPPLEMENTAIRES (+1 €).
--     Carte portrait : cheddar, reblochon, mozzarella, raclette, chevre.
--     Soso par message : raclette, cheddar, boursin, kiri, chevre.
--     Reblochon et mozzarella d'un cote, boursin et kiri de l'autre.
--
--  4. LES VIANDES AU CHOIX.
--     Carte portrait : steak, nuggets, cordon bleu, escalope, tenders,
--                      bacon, merguez.
--     Soso par message : kebab, tenders, cordon bleu, viande hachee,
--                        escalope, nuggets, bacon, merguez.
--     Le KEBAB n'est sur aucune carte, et « steak » n'est pas dans la
--     liste de Soso.
--
--  A NOTER AUSSI : ni Le Bazooka ni KSM Crousty ne figurent sur les
--  trois cartes, ce qui confirme Soso — ils sont a ajouter (migration
--  23). Et la carte portrait annonce « un burger sera propose a chaque
--  saison » : prevoir une categorie ou un plat du moment.
-- ===================================================================

select categorie, nom, prix, disponible
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
 order by categorie, prix, nom;
