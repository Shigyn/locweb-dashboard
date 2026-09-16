-- ===================================================================
--  KSM (2026-09-16) : supplement « Sauce gruyère » a 1 €.
--
--  Propose sur les tacos, les bowls et les sandwichs (carte.js v=14 :
--  SUP_GRUYERE). Sur les bowls et les sandwichs, c'est le seul
--  supplement. Un vrai produit, pour que le serveur le facture.
--
--  Rejouable.
-- ===================================================================

insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', 'Sauce gruyère', 1.00, 'Suppléments', true,
       'Sauce gruyère en plus (tacos, bowls, sandwichs)'
where not exists (
  select 1 from produits
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Sauce gruyère'
);

select nom, prix, categorie from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Sauce gruyère';
