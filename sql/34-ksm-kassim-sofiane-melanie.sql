-- ===================================================================
--  KSM : d'ou vient le nom, dans le pied de page.
--
--  Kassim, Sofiane et Melanie. Trois prenoms, trois initiales — ca se
--  raconte en une phrase et ca vaut mieux qu'un sigle que personne ne
--  comprend.
--
--  POURQUOI CE N'EST PAS QU'UN CHANGEMENT DANS LE HTML. Le paragraphe
--  du pied porte `data-editable-zone="footer_description"`, donc
--  `contenu-loader.js` remplace son contenu par la valeur de
--  `contenu_site` a chaque chargement. Modifier le HTML seul ne se
--  voit nulle part : la base gagne toujours. Les deux doivent dire la
--  meme chose, et c'est la base qui fait foi.
--
--  ET C'EST DU TEXTE NU, sans balise : le chargeur ecrit en
--  `textContent`. Un `<strong>` pose ici s'afficherait tel quel,
--  chevrons compris.
--
--  Tentee d'abord par l'API avec la cle anon : reponse 200 et ZERO
--  ligne modifiee. La politique RLS autorise la lecture, pas
--  l'ecriture — et PostgREST ne renvoie pas d'erreur dans ce cas, il
--  renvoie une liste vide. Un piege a retenir : un 200 ne veut pas
--  dire qu'on a ecrit quelque chose.
--
--  Le texte est celui dicte par Nicolas, avec l'orthographe remise
--  d'aplomb (Kassim, Melanie, notamment, place) et << Beaujolais >>
--  qui ne revient pas deux fois dans la meme phrase.
-- ===================================================================

-- AVANT
select cle_bloc, valeur
from contenu_site
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and cle_bloc = 'footer_description';

update contenu_site
set valeur = 'KSM Burger : le nom vient de Kassim, Sofiane et Mélanie. Fast-food artisanal du Beaujolais, burgers frais et faits maison, notamment nommés d''après les 12 crus de la région. Commande à emporter, à récupérer sur place.'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and cle_bloc = 'footer_description';

-- APRES. La phrase doit commencer par << KSM Burger : le nom vient >>.
select cle_bloc, valeur
from contenu_site
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and cle_bloc = 'footer_description';
