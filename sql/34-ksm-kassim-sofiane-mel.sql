-- ===================================================================
--  KSM : dire ce que veut dire KSM.
--
--  Kassim, Sofiane et Mel. Trois prenoms, trois initiales — ca se
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
-- ===================================================================

-- AVANT
select cle_bloc, valeur
from contenu_site
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and cle_bloc = 'footer_description';

update contenu_site
set valeur = 'KSM, ce sont Kassim, Sofiane et Mel. Le fast-food artisanal du Beaujolais : burgers frais, faits maison, nommés d''après les crus locaux. Commande à emporter, à récupérer sur place.'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and cle_bloc = 'footer_description';

-- APRES. La phrase doit commencer par << KSM, ce sont >>.
select cle_bloc, valeur
from contenu_site
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and cle_bloc = 'footer_description';
