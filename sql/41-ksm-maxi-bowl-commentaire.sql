-- ===================================================================
--  KSM (2026-09-16) : message du client, Maxi Bowl, Nutella a 1 €.
--
--  - `commandes.commentaire` : le client peut laisser un message en fin
--    de commande (allergie, precision). Ecrit APRES la creation par
--    create-commande-retrait, comme l'heure : une colonne absente ne
--    fait jamais perdre une commande.
--  - Maxi Bowl a 15 € : le bowl en double portion, deux viandes au
--    choix (carte.js v=13). Sans photo pour l'instant : image_url vide,
--    l'emplacement se remplit depuis l'editeur.
--  - Supplement Nutella de la gaufre : + 1 € (et non 0,50 €).
--
--  Rejouable.
-- ===================================================================

alter table commandes add column if not exists commentaire text;

insert into produits (client_id, nom, prix, categorie, disponible, description, image_url)
select 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', 'Maxi Bowl', 15.00, 'Bowls', true,
       'Le bowl en plus grand : double portion, deux viandes au choix, fromage au choix, sauce, oignons frits',
       null
where not exists (
  select 1 from produits
  where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Maxi Bowl'
);

update produits set prix = 1.00
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b' and nom = 'Nutella' and categorie = 'Suppléments';

-- Verification.
select nom, prix, categorie, image_url
from produits
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
  and nom in ('Maxi Bowl', 'Bowl', 'Nutella', 'Kinder Bueno')
order by nom;
