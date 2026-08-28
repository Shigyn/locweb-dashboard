-- ===================================================================
--  17 — La section Chantiers, seulement pour ceux que ça concerne.
--
--  A executer apres 16.
--
--  Les photos avant / apres n'ont de sens que pour une prestation qui
--  transforme quelque chose : une toiture, une facade, un jardin. Un
--  restaurateur, un coach ou un photographe n'a rien a y mettre, et
--  une section vide dans son editeur ne fait que l'encombrer.
--
--  `null`  -> on decide d'apres le secteur : oui pour un artisan,
--             non pour les autres. C'est le cas de la quasi-totalite
--             des clients, et personne n'a rien a regler.
--  `true`  -> force l'affichage, quel que soit le secteur. Pour le
--             paysagiste declare « independant », ou le carreleur qui
--             s'est trompe de case a l'inscription.
--  `false` -> masque, meme pour un artisan qui n'en veut pas.
-- ===================================================================

alter table clients
  add column if not exists chantiers boolean;

comment on column clients.chantiers is
  'Section Chantiers (photos avant/apres) dans l editeur. null = selon le secteur (artisan uniquement), true/false = choix explicite fait a la mise en place.';


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------
--  Ce que chaque client verra, avec la regle appliquee.

select c.nom_site,
       p.secteur,
       c.chantiers as choix_explicite,
       coalesce(c.chantiers, p.secteur = 'artisan') as section_affichee
from clients c
left join profils_client p on p.client_id = c.id
order by c.nom_site;
