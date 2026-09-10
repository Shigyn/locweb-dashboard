-- ===================================================================
--  KSM : les quatorze burgers sont recadres a l'identique.
--
--  LE PROBLEME. Les vignettes etaient decoupees en carre a meme la
--  photo, avec un cadrage regle a la main image par image. Le Bazooka
--  et le Triple Julienas, qui sont hauts, sortaient du cadre en haut ET
--  en bas ; le Beaujolais etait un gros plan sur du bacon ; le Chenas
--  et les deux fish, plus petits dans leur image, avaient de l'air
--  autour. Aucune uniformite d'une ligne a l'autre.
--
--  CE QUI A CHANGE. Ce n'est plus le CADRE qui est fixe, c'est LE
--  BURGER : sa plus grande dimension vaut la meme fraction de la
--  vignette dans les quatorze cas, et il est centre. Un burger haut est
--  donc etroit avec du fond sur les cotes, un burger large touche
--  presque les bords — mais tous ont la meme presence.
--
--  Le fond manquant n'est pas une bande unie : c'est la photo
--  elle-meme, agrandie, fortement floutee et assombrie, avec le burger
--  net fondu par-dessus. Aucun bord franc, et la couleur reste celle de
--  la photo.
--
--  LES SEPT IMAGES GENEREES REJOIGNENT LE DEPOT. Chenas, les deux
--  fish, Fleurie, Julienas et Regnie vivaient sur le stockage Supabase.
--  Elles sont desormais dans `plats/` comme les autres : versionnees,
--  au meme format, servies par le meme domaine.
--
--  ET TOUT PASSE SUR KSMBURGER.FR. Dix-huit produits pointaient encore
--  vers shigyn.github.io — ca fonctionne encore, mais un site qui
--  charge ses images depuis son ancienne adresse est un site a moitie
--  demenage.
--
--  A SAVOIR : le Beaujolais reste un gros plan. Sa photo d'origine en
--  est un — le pain est coupe en haut dans la source elle-meme. On ne
--  recadre pas ce qui n'a jamais ete photographie. A refaire le jour ou
--  KSM reprend la photo.
-- ===================================================================

-- AVANT
select nom, image_url
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and categorie = 'Burgers'
order by nom;

-- -------------------------------------------------------------------
--  1. Les quatorze burgers, par identifiant : aucun risque d'accent
--     ou d'espace mal recopie dans un nom.
-- -------------------------------------------------------------------
update produits p
set image_url = v.url
from (values
  ('83a968a0-3eda-464d-a420-d4f95a22c7f4'::uuid, 'https://ksmburger.fr/plats/le-bazooka.webp'),
  ('edfbfc55-055d-4058-bb5f-9884803d3193'::uuid, 'https://ksmburger.fr/plats/le-beaujolais.webp'),
  ('355f403b-172c-481f-8c96-73ab437cf98d'::uuid, 'https://ksmburger.fr/plats/le-chenas.webp'),
  ('423be288-1f6b-4fc9-a3a8-e377ae5a59ac'::uuid, 'https://ksmburger.fr/plats/le-chiroubles.webp'),
  ('9b66b4b3-e8df-431f-8834-0d51b6adb2df'::uuid, 'https://ksmburger.fr/plats/le-double-filet-o-fish.webp'),
  ('6dc2421a-6215-4f00-8a20-8bf3d78a6c1e'::uuid, 'https://ksmburger.fr/plats/le-filet-o-fish.webp'),
  ('fd2f2358-e3ca-40c8-b620-21b84ad0b498'::uuid, 'https://ksmburger.fr/plats/le-fleurie.webp'),
  ('91895d22-42a7-4eb2-a47b-c499daf00f21'::uuid, 'https://ksmburger.fr/plats/le-julienas.webp'),
  ('12d13945-ca3f-4727-a40c-193d576e6edd'::uuid, 'https://ksmburger.fr/plats/le-morgon.webp'),
  ('f66a7c46-90ad-499a-b9c1-8f7d4dee9bdb'::uuid, 'https://ksmburger.fr/plats/le-moulin-a-vent.webp'),
  ('29bcf77f-d177-4621-b919-6f9751956035'::uuid, 'https://ksmburger.fr/plats/le-regnie.webp'),
  ('3d8355a1-7ff9-47e7-8fe5-b85d6c82208a'::uuid, 'https://ksmburger.fr/plats/le-saint-amour.webp'),
  ('196bc31e-cb5e-4363-9172-08e1858ec21a'::uuid, 'https://ksmburger.fr/plats/le-triple-cheese-bacon.webp'),
  ('5fb9baa9-ae4a-4578-bf87-6906c7aa58c6'::uuid, 'https://ksmburger.fr/plats/le-triple-julienas.webp')
) as v(id, url)
where p.id = v.id
  and p.client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';

-- -------------------------------------------------------------------
--  2. Tout le reste de la carte quitte l'ancienne adresse.
-- -------------------------------------------------------------------
update produits
set image_url = replace(image_url, 'https://shigyn.github.io/Ksm/', 'https://ksmburger.fr/')
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and image_url like 'https://shigyn.github.io/Ksm/%';

-- -------------------------------------------------------------------
--  APRES. `ancien_domaine` et `stockage_supabase` doivent valoir 0.
-- -------------------------------------------------------------------
select
  count(*) filter (where image_url like '%ksmburger.fr%')        as nouveau_domaine,
  count(*) filter (where image_url like '%shigyn.github.io%')    as ancien_domaine,
  count(*) filter (where image_url like '%supabase.co/storage%') as stockage_supabase,
  count(*) filter (where image_url is null or image_url = '')    as sans_photo
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';

select nom, image_url
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and categorie = 'Burgers'
order by nom;
