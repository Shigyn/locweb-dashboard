-- ===================================================================
--  KSM Burger — la formule menu (frites + boisson) a 3 €
--
--  POURQUOI UN PRODUIT ET PAS UNE CASE A COCHER DANS LE CODE.
--
--  Le total qui fait foi n'est pas celui qu'affiche le navigateur :
--  c'est celui que le serveur recalcule depuis la table `produits`,
--  sinon n'importe qui commande un burger a 0 € en modifiant la page.
--
--  Consequence directe : une option PAYANTE qui n'existe pas comme
--  produit ne serait facturee nulle part. Le client lirait 15 € et
--  paierait 12 € au comptoir. La formule menu est donc une ligne de
--  la categorie « Suppléments », exactement comme le bacon ou le
--  cheddar — c'est ce qui la rend payante sans une seule ligne de
--  code cote serveur.
--
--  LE NOM COMPTE AUSSI. `carte.js` reconnait cette ligne a son nom
--  (`/^formule\s*menu$/i`) pour deux raisons :
--    1. la sortir des familles de supplements — a 3 €, la regle de
--       classement par prix la rangerait parmi les VIANDES, entre le
--       bacon et le steak supplementaire ;
--    2. lui donner son propre encadre en tete de fiche, avec le choix
--       de la boisson.
--  Renommer ce produit depuis l'espace client casserait les deux.
-- ===================================================================

insert into produits (client_id, nom, prix, categorie, disponible, description)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b',
       'Formule menu',
       3.00,
       'Suppléments',
       true,
       'Frites et une boisson 33cl'
where not exists (
  select 1 from produits p
   where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
     and p.categorie = 'Suppléments'
     and lower(btrim(p.nom)) = 'formule menu'
);

-- -------------------------------------------------------------------
--  VERIFICATION
--
--  Attendu : une ligne « Formule menu » a 3,00 €, disponible.
--
--  Les boissons listees en dessous sont celles que la fiche proposera
--  dans la formule : `carte.js` prend les 33cl a 2,50 € ou moins,
--  pour qu'une limonade a 3 € ne parte pas dans un menu a 3 €.
-- -------------------------------------------------------------------
select nom, prix, categorie, disponible
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and (lower(btrim(nom)) = 'formule menu'
        or (categorie = 'Boissons' and nom ilike '%33cl%'))
 order by categorie, nom;
