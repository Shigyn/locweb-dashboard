-- ===================================================================
--  KSM Burger — les supplements payants
--
--  Demande du 2026-09-04 : une viande en plus a 3 €, les garnitures
--  classiques a 1 €, sur les burgers et les tacos.
--
--  POURQUOI DES PRODUITS ET PAS UNE LISTE DANS LE CODE.
--
--  Jusqu'ici aucune option ne coutait un centime, et c'etait
--  volontaire : la fonction de commande recalcule TOUJOURS le total
--  depuis `produits`, sans jamais faire confiance au panier envoye par
--  le navigateur. Une option payante ecrite en dur dans la page aurait
--  ete ignoree par le serveur, et l'addition affichee au client aurait
--  diverge de celle encaissee.
--
--  En faisant des supplements de vrais produits, le serveur connait
--  leur prix sans une ligne de code de plus, et Kassim les modifie
--  depuis son espace comme n'importe quel plat.
--
--  La categorie « Supplements » est masquee de la carte publique par
--  `carte.js` : on ne commande pas un cheddar tout seul, il ne se
--  choisit que dans la fiche d'un plat.
-- ===================================================================

-- A RELIRE AVEC KASSIM : cette liste est la seule chose ici qui ne
-- vienne pas de lui. Les prix sont ceux qu'il a donnes (3 € la viande,
-- 1 € la garniture) ; les parfums sont les classiques d'un snack, a
-- confirmer avant d'ouvrir aux clients. Un supplement propose mais
-- indisponible, c'est un appel et une commande a refaire.

insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', v.nom, v.prix, 'Suppléments', true, v.description
from (values
  ('Steak supplémentaire', 3.00, 'Un steak haché de plus'),
  ('Cheddar',              1.00, null),
  ('Raclette',             1.00, null),
  ('Chèvre',               1.00, null),
  ('Œuf',                  1.00, null),
  ('Bacon',                1.00, null),
  ('Oignons frits',        1.00, null),
  ('Cornichons',           1.00, null),
  ('Sauce supplémentaire', 1.00, null)
) as v(nom, prix, description)
-- Rejouable sans creer de doublon : le script peut etre relance apres
-- une correction de prix sans qu'on se retrouve avec deux cheddars.
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and lower(btrim(p.nom)) = lower(v.nom)
     and p.categorie = 'Suppléments'
);

-- Verification : doit ramener 9 supplements, et 34 plats hors
-- supplements (la carte reelle ne bouge pas).
select
  count(*) filter (where categorie = 'Suppléments')  as supplements,
  count(*) filter (where categorie <> 'Suppléments') as plats
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';
