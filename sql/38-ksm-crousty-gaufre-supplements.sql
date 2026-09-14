-- ===================================================================
--  KSM : supplements du Crousty et de la gaufre (2026-09-15).
--
--  Demandes de Kassim relayees par Nicolas :
--   - KSM Crousty : riz en plus 2 €, tenders en plus 2 € (plus les
--     fromages, deja en base) ;
--   - Gaufre : sucre 4 €, Nutella 4,50 €, Kinder Bueno 5 €, chantilly
--     + 0,50 €.
--
--  Les supplements sont de vrais produits : la fonction de commande
--  recalcule le total depuis `produits`, un prix ecrit seulement dans le
--  navigateur ne serait jamais facture. `carte.js` (v=12) ne les montre
--  que sur leur plat (SUP_CROUSTY, SUP_GAUFRE).
--
--  Rejouable : chaque insertion verifie que la ligne n'existe pas deja.
-- ===================================================================

insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, 'Suppléments', true, v.description
from (values
  ('Riz en plus',     2.00, 'KSM Crousty : une portion de riz en plus'),
  ('Tenders en plus', 2.00, 'KSM Crousty : des tenders en plus'),
  ('Nutella',         0.50, 'Gaufre au Nutella'),
  ('Kinder Bueno',    1.00, 'Gaufre au Kinder Bueno'),
  ('Chantilly',       0.50, 'Chantilly sur la gaufre')
) as v(nom, prix, description)
where not exists (
  select 1 from produits p
  where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and p.nom = v.nom
);

-- La gaufre coute 4 € : c'est la gaufre au sucre, le reste s'ajoute.
update produits
set prix = 4.00,
    description = 'Une gaufre moelleuse, au sucre, au Nutella ou au Kinder Bueno, avec de la chantilly si vous le souhaitez.'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Gaufre';

-- La bouteille d'eau entre dans le menu : la formule ne dit plus « 33cl ».
update produits
set description = 'Frites et une boisson'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Formule menu';

-- Verification.
select nom, prix, categorie, description
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and nom in ('Riz en plus', 'Tenders en plus', 'Nutella', 'Kinder Bueno', 'Chantilly', 'Gaufre', 'Formule menu')
order by nom;
