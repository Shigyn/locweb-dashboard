-- ===================================================================
--  KSM Burger — rendre les photos visibles dans l'editeur
--
--  LE PROBLEME. La migration 26 avait vide `image_url` pour que le
--  site retombe sur ses photos recadrees, celles qui n'ont pas le
--  texte des affiches. C'etait juste pour le SITE.
--
--  Mais l'EDITEUR n'affiche que ce champ : il ne connait pas la
--  table de photos de `carte.js`. Cote client, la carte s'est donc
--  retrouvee sans une seule vignette — cinquante produits, zero
--  image. Le site allait bien, l'editeur etait aveugle.
--
--  LA CORRECTION. On ecrit en base les URL ABSOLUES des memes
--  fichiers. L'editeur les affiche, le site les prend aussi
--  (`image_url` gagne sur la table locale) et montre exactement la
--  meme image. Et Kassim peut enfin remplacer n'importe laquelle
--  depuis son espace, ce qui etait le but depuis le debut.
--
--  A jouer d'un bloc. Le select final montre le resultat.
-- ===================================================================

update produits p
   set image_url = v.url
  from (values
    ('Le Bazooka',                  'https://shigyn.github.io/Ksm/plats/le-bazooka.webp'),
    ('Le Beaujolais',               'https://shigyn.github.io/Ksm/plats/le-beaujolais.webp'),
    ('Le Chénas',                   'https://shigyn.github.io/Ksm/plats/double-cheddar.webp'),
    ('Le Chiroubles',               'https://shigyn.github.io/Ksm/plats/le-chiroubles.webp'),
    ('Le Fleurie',                  'https://shigyn.github.io/Ksm/plats/le-fleurie.webp'),
    ('Le Juliénas',                 'https://shigyn.github.io/Ksm/plats/le-julienas.webp'),
    ('Le Morgon',                   'https://shigyn.github.io/Ksm/plats/le-morgon.webp'),
    ('Le Moulin à Vent',            'https://shigyn.github.io/Ksm/plats/le-moulin-a-vent.webp'),
    ('Le Regnié',                   'https://shigyn.github.io/Ksm/plats/smash-burger.webp'),
    ('Le Saint Amour',              'https://shigyn.github.io/Ksm/plats/le-saint-amour.webp'),
    ('Le Triple Cheese Bacon',      'https://shigyn.github.io/Ksm/plats/le-triple-cheese-bacon.webp'),
    ('Le Triple Juliénas',          'https://shigyn.github.io/Ksm/plats/le-triple-julienas.webp'),
    ('KSM Crousty',                 'https://shigyn.github.io/Ksm/plats/ksm-crousty.webp'),
    ('Maxi Tacos',                  'https://shigyn.github.io/Ksm/plats/tacos-boursin.webp'),
    ('Tacos simple',                'https://shigyn.github.io/Ksm/plats/tacos.webp'),
    ('Le Boursin',                  'https://shigyn.github.io/Ksm/plats/le-boursin.webp'),
    ('Le Chef',                     'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=640&h=640&fit=crop&q=75'),
    ('Le Kebab',                    'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=640&h=640&fit=crop&q=75'),
    ('Bowl',                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=640&h=640&fit=crop&q=75'),
    ('Salade César',                'https://shigyn.github.io/Ksm/plats/salade-cesar.webp'),
    ('Salade chèvre chaud',         'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=640&h=640&fit=crop&q=75'),
    ('Bouchées camembert x6',       'https://shigyn.github.io/Ksm/plats/bouchees-camembert.webp'),
    ('Box à partager',              'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=640&h=640&fit=crop&q=75'),
    ('Cheeseburger',                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=640&h=640&fit=crop&q=75'),
    ('Jalapeños x6',                'https://shigyn.github.io/Ksm/plats/jalapenos.webp'),
    ('Nuggets x6',                  'https://shigyn.github.io/Ksm/plats/nuggets.webp'),
    ('Tenders maison x5',           'https://shigyn.github.io/Ksm/plats/tenders.webp'),
    ('Frites',                      'https://images.unsplash.com/photo-1630431341973-02e1b662ec35?w=640&h=640&fit=crop&q=75'),
    ('Frites bacon cheddar',        'https://images.unsplash.com/photo-1598679253544-2c97992403ea?w=640&h=640&fit=crop&q=75'),
    ('Frites cheddar',              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=640&h=640&fit=crop&q=75'),
    ('Frites gruyère',              'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=640&h=640&fit=crop&q=75'),
    ('Frites gruyère bacon',        'https://shigyn.github.io/Ksm/plats/frite-gruyere-bacon.webp'),
    ('Frites jalapeños',            'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?w=640&h=640&fit=crop&q=75'),
    ('Frites oignons frits',        'https://images.unsplash.com/photo-1585109649139-366815a0d713?w=640&h=640&fit=crop&q=75'),
    ('Menu enfant',                 'https://images.unsplash.com/photo-1610614819513-58e34989848b?w=640&h=640&fit=crop&q=75'),
    ('Confiseries',                 'https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=640&h=640&fit=crop&q=75'),
    ('Donuts',                      'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=640&h=640&fit=crop&q=75'),
    ('Gaufre',                      'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=640&h=640&fit=crop&q=75'),
    ('Milkshake',                   'https://images.unsplash.com/photo-1553787499-6f9133860278?w=640&h=640&fit=crop&q=75'),
    ('Milkshake gourmand',          'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=640&h=640&fit=crop&q=75'),
    ('Tiramisu',                    'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=640&h=640&fit=crop&q=75'),
    ('Canette 33cl',                'https://images.unsplash.com/photo-1581636625402-29b2a704ef13?w=640&h=640&fit=crop&q=75'),
    ('Coca-Cola 33cl',              'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=640&h=640&fit=crop&q=75'),
    ('Eau minérale 50cl',           'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=640&h=640&fit=crop&q=75'),
    ('Ice Tea 33cl',                'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=640&h=640&fit=crop&q=75'),
    ('Limonade artisanale 33cl',    'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=640&h=640&fit=crop&q=75')
  ) as v(nom, url)
 where p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and lower(btrim(p.nom)) = lower(v.nom);

-- -------------------------------------------------------------------
--  LES QUATRE SANS PHOTO RESTENT SANS PHOTO
--
--  Le Double filet ô fish, Le Filet ô fish, Tarte au Daim, Bouteille.
--
--  Aucune image honnete n'existe pour elles : montrer un burger au
--  boeuf sur un filet de colin, c'est promettre au comptoir un plat
--  qu'on ne sert pas. Elles sont sur PHOTOS-A-DEMANDER.md.
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
--  VERIFICATION
--  Attendu : 46 avec photo, 4 sans.
-- -------------------------------------------------------------------
select count(*) filter (where image_url is not null) as avec_photo,
       count(*) filter (where image_url is null)     as sans_photo
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and categorie <> 'Suppléments';
