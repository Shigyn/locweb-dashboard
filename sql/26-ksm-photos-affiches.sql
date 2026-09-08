-- ===================================================================
--  KSM Burger — retirer les image_url qui court-circuitent les photos
--
--  POURQUOI. `carte.js` donne la priorite a `image_url` sur ses
--  propres photos : c'est voulu, une photo choisie par le
--  restaurateur doit gagner. Mais treize lignes portent encore des
--  valeurs posees avant la seance photo, et ce sont elles qui
--  s'affichent :
--
--   - 8 AFFICHES BRUTES en 1024 x 1536, avec « KSM BURGER » ecrit en
--     haut et le nom du cru en bas. Elles sont en portrait, donc elles
--     etiraient aussi leur carte d'un tiers et cassaient la grille.
--     (Le carre est desormais verrouille en CSS, mais le texte des
--     affiches, lui, resterait.)
--
--   - 1 fichier .HEIC (Maxi Tacos). Aucun navigateur ne decode ce
--     format : la carte affichait l'icone d'image brisee.
--
--   - 4 photos Unsplash qui montrent les burgers d'AUTRES
--     restaurants. Elles avaient ete retirees du code le 2026-09-07,
--     mais la base les remettait par-dessus.
--
--  CE QU'ON FAIT. On vide `image_url`. Le site retombe alors sur les
--  vraies photos du restaurant, recadrees en 640 x 640 pour supprimer
--  le texte des affiches (`clients/Ksm/plats/`). Rien n'est supprime
--  d'autre : les fichiers restent dans le stockage Supabase, et
--  Kassim peut reposer une photo depuis son espace quand il veut.
--
--  A jouer d'un bloc. Le select final montre le resultat.
-- ===================================================================

update produits
   set image_url = null
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
   and image_url is not null
   and (
        --  Les affiches et le .HEIC : tout ce qui vient du stockage
        --  et n'a jamais ete recadre.
        image_url like '%/storage/v1/object/public/site-images/%'
        --  Les photos d'autres restaurants.
     or image_url like '%images.unsplash.com%'
   );

-- -------------------------------------------------------------------
--  VERIFICATION
--
--  Attendu : `restantes` = 0. Toute ligne qui subsiste ici est une
--  photo posee par le restaurateur lui-meme, et doit etre laissee.
-- -------------------------------------------------------------------
select count(*) filter (where image_url is not null) as restantes,
       count(*)                                      as produits
  from produits
 where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';
