-- ===================================================================
--  KSM : la sauce burger entre dans la recette.
--
--  Le burger n'a plus de choix de sauce sur le site (carte.js, v9) :
--  il vient avec la sauce burger de la maison. Ce n'est donc plus une
--  option a trancher, c'est un ingredient — et un ingredient se lit
--  dans la description, avant de commander.
--
--  Trois cas dans les quatorze burgers, et ils ne se traitent pas
--  pareil :
--
--    1. huit finissent par << , sauce >> tout court, ce qui ne disait
--       pas laquelle : elles deviennent << , sauce burger >> ;
--    2. cinq n'en mentionnent aucune : on ajoute a la fin ;
--    3. le Bazooka finit par une phrase (<< Le plus gros de la
--       carte. >>). Ajouter apres donnerait << ... de la carte, sauce
--       burger >>. On insere donc AVANT cette phrase.
--
--  Les trois passes sont idempotentes : elles ignorent tout ce qui
--  contient deja << sauce burger >>. Rejouer le script ne double rien.
--
--  A VERIFIER AVEC KSM AVANT DE LANCER : les deux burgers au poisson
--  (Filet o fish et Double filet o fish) recoivent eux aussi la sauce
--  burger, puisque la consigne est << sur tout burger >>. S'ils sont
--  servis avec une sauce tartare ou autre chose, il faut les corriger
--  a la main apres coup, ou les exclure ici.
-- ===================================================================

-- -------------------------------------------------------------------
--  AVANT. A lire, et a garder sous les yeux : c'est le seul filet
--  avant une ecriture sur les quatorze lignes.
-- -------------------------------------------------------------------
select nom, description
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and lower(categorie) like '%burger%'
order by nom;

-- -------------------------------------------------------------------
--  1. Celles qui finissent par << , sauce >> : on precise laquelle.
-- -------------------------------------------------------------------
update produits
set description = regexp_replace(description, ',\s*sauce\s*$', ', sauce burger')
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and lower(categorie) like '%burger%'
  and description ~* ',\s*sauce\s*$'
  and description !~* 'sauce burger';

-- -------------------------------------------------------------------
--  2. Le Bazooka et tout autre burger dont la description se termine
--     par une phrase : on insere avant elle, pas apres.
--
--     Le motif attrape la DERNIERE phrase complete precedee d'un
--     point : << ... oignons rouges. Le plus gros de la carte. >>
--     devient << ... oignons rouges, sauce burger. Le plus gros de la
--     carte. >>
-- -------------------------------------------------------------------
update produits
set description = regexp_replace(description, '^(.*?)(\.\s)', '\1, sauce burger\2')
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and lower(categorie) like '%burger%'
  and description ~ '\.\s'
  and description !~* 'sauce';

-- -------------------------------------------------------------------
--  3. Le reste : aucune sauce nommee, aucune phrase finale. On ajoute
--     simplement au bout.
-- -------------------------------------------------------------------
update produits
set description = rtrim(description, ' .,') || ', sauce burger'
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and lower(categorie) like '%burger%'
  and description !~* 'sauce';

-- -------------------------------------------------------------------
--  APRES. `sans_sauce_burger` doit valoir 0.
-- -------------------------------------------------------------------
select
  count(*)                                                   as burgers,
  count(*) filter (where description ~* 'sauce burger')       as avec_sauce_burger,
  count(*) filter (where description !~* 'sauce burger')      as sans_sauce_burger
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and lower(categorie) like '%burger%';

select nom, description
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and lower(categorie) like '%burger%'
order by nom;
