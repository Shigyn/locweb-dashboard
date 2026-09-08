-- ===================================================================
--  KSM Burger — nettoyage des doublons crees par la migration 24
--
--  CE FICHIER REPARE MON ERREUR. La migration 24 testait l'existence
--  d'un produit sur son nom EXACT. Les frites etaient deja en base au
--  singulier (« Frite cheddar ») et je les ai reinserees au pluriel
--  (« Frites cheddar ») : le test n'a rien vu, et la carte affiche
--  desormais chaque frite deux fois.
--
--  Neuf doublons au total, tous crees par moi il y a quelques minutes.
--  On garde systematiquement la ligne PREEXISTANTE — elle peut etre
--  citee dans une commande passee, la mienne non.
--
--  A jouer d'un bloc. Le select final montre le resultat.
-- ===================================================================

-- -------------------------------------------------------------------
--  1. SUPPRIMER LES DOUBLONS QUE J'AI CREES
--
--     Chaque ligne supprimee est nommee avec sa jumelle preexistante.
--     La suppression ne vise QUE le nom exact que la migration 24 a
--     insere, jamais l'ancien.
-- -------------------------------------------------------------------
delete from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and nom in (
     'Frites',                --  double de « Frite simple »
     'Frites cheddar',        --  double de « Frite cheddar »
     'Frites gruyère',        --  double de « Frite gruyère »
     'Frites bacon cheddar',  --  double de « Frite cheddar bacon »
     'Frites gruyère bacon',  --  double de « Frite gruyère bacon »
     'Frites oignons frits',  --  double de « Frite oignons frits »
     'Donut''s',              --  double de « Donuts »
     'Tarte Daim',            --  double de « Tarte au Daim »
     'Eau 50cl'               --  double de « Eau minérale 50cl »
   );

-- -------------------------------------------------------------------
--  1 bis. LES FRITES PASSENT AU PLURIEL
--
--     La carte imprimee dit « FRITES ». La base disait « Frite
--     cheddar », « Frite simple » — au singulier, ce qui se lit mal
--     quand on en commande une barquette.
--
--     L'ORDRE COMPTE : on renomme APRES avoir supprime les doublons
--     ci-dessus. Renommer d'abord ferait entrer « Frite cheddar » en
--     collision avec le « Frites cheddar » que je venais de creer.
-- -------------------------------------------------------------------
update produits p
   set nom = v.neuf
  from (values
    ('Frite simple',        'Frites'),
    ('Frite cheddar',       'Frites cheddar'),
    ('Frite cheddar bacon', 'Frites bacon cheddar'),
    ('Frite gruyère',       'Frites gruyère'),
    ('Frite gruyère bacon', 'Frites gruyère bacon'),
    ('Frite oignons frits', 'Frites oignons frits')
  ) as v(ancien, neuf)
 where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(p.nom)) = lower(v.ancien);

--  Une description mal saisie tant qu'on y est : « frite , sauce
--  gruyere , bacon » — espaces avant les virgules, pas d'accents.
update produits
   set description = 'Frites, sauce gruyère maison, bacon'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(nom)) = 'frites gruyère bacon';

-- -------------------------------------------------------------------
--  2. TROIS PRIX NE CORRESPONDENT PAS A LA CARTE OFFICIELLE
--
--     Decouverts en comparant l'ecran a la carte papier. Ils etaient
--     deja faux AVANT mes migrations — la 24 ne les a pas touches
--     puisque ces produits existaient deja.
--
--     Maxi Tacos  : 12,00 en base, 10 € sur la carte
--     Bowl        : 10,00 en base,  8 € sur la carte
--     Menu enfant :  8,00 en base,  6 € sur la carte
--
--     Trois euros de trop sur un menu enfant, c'est le genre d'ecart
--     qu'un client remarque au comptoir.
-- -------------------------------------------------------------------
update produits set prix = 10.00
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(nom)) = 'maxi tacos';

update produits set prix = 8.00,
       description = 'Riz, viande au choix, fromage au choix, sauce, frites, oignons frits'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(nom)) = 'bowl';

update produits set prix = 6.00,
       description = '4 nuggets ou mini burger, frites, Capri-Sun ou eau aromatisée, compote ou Tops'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(nom)) = 'menu enfant';

-- -------------------------------------------------------------------
--  3. LES CATEGORIES SE CHEVAUCHAIENT
--
--     « Salades et Desserts » contenait des desserts alors qu'une
--     categorie « Desserts » existe a cote : les tartes se trouvaient
--     dans deux endroits differents du menu. On range les desserts
--     avec les desserts, et « Salades et Desserts » redevient
--     « Salades ».
--
--     C'est aussi ce que demandait Soso : « Salade et dessert si on
--     peux y separer ».
-- -------------------------------------------------------------------
update produits set categorie = 'Desserts'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie = 'Salades et Desserts'
   and lower(btrim(nom)) in ('donuts', 'gaufre', 'tarte au daim', 'tiramisu');

update produits set categorie = 'Salades'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie = 'Salades et Desserts';

--  Meme chose pour le snacking, coupe en deux categories.
update produits set categorie = 'Snacking'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie = 'Bowls et Snacking'
   and lower(btrim(nom)) not in ('bowl');

update produits set categorie = 'Bowls'
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie = 'Bowls et Snacking';

-- -------------------------------------------------------------------
--  4. UN PRODUIT NOMME « SNACKING »
--
--     Il existe une ligne « Snacking » a 6,00 € dans la categorie du
--     meme nom. C'est probablement un reste de mise en place : un
--     client ne commande pas « un snacking ». On la retire de la
--     carte sans la supprimer, au cas ou elle serait citee ailleurs.
-- -------------------------------------------------------------------
update produits set disponible = false
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(nom)) = 'snacking';

-- -------------------------------------------------------------------
--  VERIFICATION
--  Attendu : plus aucune ligne en double, et les trois prix corriges.
-- -------------------------------------------------------------------
select categorie, count(*) as lignes
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie <> 'Suppléments'
 group by categorie
 order by categorie;
