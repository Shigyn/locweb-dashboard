-- ===================================================================
--  KSM (2026-09-16) : la « Sauce gruyère » a 1 €.
--
--  Premiere version : un nouveau produit « Sauce gruyère ». Mais la
--  base avait deja « Gruyère maison » a 1 € (description « Sauce au
--  choix ») sur les burgers et les tacos : le meme supplement, affiche
--  deux fois sur les tacos. Fusion : on garde le produit existant,
--  renomme « Sauce gruyère », et on supprime le doublon (jamais
--  commande, verifie dans commande_articles).
--
--  carte.js v=15 : proposee sur les burgers et tacos (comme avant) et
--  desormais sur les bowls et les sandwichs, ou c'est le seul
--  supplement.
--
--  Rejouable.
-- ===================================================================

delete from produits p
where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and p.nom = 'Sauce gruyère'
  and exists (select 1 from produits g
              where g.client_id = p.client_id and g.nom = 'Gruyère maison')
  and not exists (select 1 from commande_articles a where a.produit_id = p.id);

update produits
set nom = 'Sauce gruyère', description = 'Sauce gruyère maison'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Gruyère maison';

select nom, prix, categorie, description from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and (nom ilike '%gruy%');
