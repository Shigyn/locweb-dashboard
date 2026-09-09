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