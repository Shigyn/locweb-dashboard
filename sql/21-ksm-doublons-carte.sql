-- ===================================================================
--  KSM Burger — six plats en double dans la carte
--
--  Renumerote de 19 en 21 le 2026-09-04 : collision de numero.
--
--  Constate le 2026-09-01 : la table `produits` contient 40 lignes
--  pour 34 plats reels. Six paires sont identiques a la ligne pres —
--  meme nom, meme prix, meme categorie, toutes disponibles :
--
--     Le Beaujolais 12 €       Le Fleurie 12 €
--     Le Moulin à Vent 12 €    Le Triple Cheese Bacon 16 €
--     Frite simple 3 €         Frite cheddar bacon 4,50 €
--
--  Sur un site dont l'unique fonction est la commande, un plat
--  affiche deux fois n'est pas un defaut d'affichage : c'est une
--  commande fausse, et un client qui se demande ce qui distingue les
--  deux lignes. Le nouveau site les masque deja cote visiteur, mais
--  Kassim continue de les voir dans son espace, et le prochain import
--  les ramenerait.
--
--  Ce fichier ne supprime QUE les doublons parfaits, et garde
--  toujours un exemplaire. Deux plats de meme nom mais de prix
--  differents sont deux plats reels : ils ne sont pas touches.
-- ===================================================================

-- 1. A regarder d'abord — ce qui va partir.
select p.id, p.nom, p.prix, p.categorie
  from produits p
 where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and p.ctid <> (
     select min(q.ctid) from produits q
      where q.client_id = p.client_id
        and lower(btrim(q.nom)) = lower(btrim(p.nom))
        and q.prix = p.prix
        and coalesce(q.categorie, '') = coalesce(p.categorie, '')
   )
 order by p.nom;

-- 2. La suppression.
--    La clause `not exists` est la garantie qu'aucune commande deja
--    passee ne perd la reference de son article : `commande_articles`
--    pointe vers `produits`, et supprimer un produit commande ferait
--    echouer la suppression (ou pire, laisserait un historique muet).
delete from produits p
 where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and p.ctid <> (
     select min(q.ctid) from produits q
      where q.client_id = p.client_id
        and lower(btrim(q.nom)) = lower(btrim(p.nom))
        and q.prix = p.prix
        and coalesce(q.categorie, '') = coalesce(p.categorie, '')
   )
   and not exists (
     select 1 from commande_articles ca where ca.produit_id = p.id
   );

-- 3. Verification — doit ramener 34.
select count(*) as plats_restants
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';
