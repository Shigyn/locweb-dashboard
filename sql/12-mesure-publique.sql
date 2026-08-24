-- ===================================================================
--  12 — Le site va chercher son propre identifiant de mesure.
--
--  A executer apres 11.
--
--  Probleme resolu : apres la connexion Google, la base connait l'ID de
--  mesure GA4 du client (`ga4_measurement_id`, rempli automatiquement
--  par oauth-google-echange). Mais le site est un fichier statique sur
--  GitHub Pages — rien ne peut ecrire dedans. Il fallait donc coller le
--  G-XXXXXXXXXX a la main dans chaque site, et c'est precisement le
--  geste qu'on oublie : un client affiche alors zero visiteur pendant
--  des mois sans que rien ne le signale.
--
--  Avec cette vue, `clients/mesure.js` demande son identifiant au
--  demarrage. Le client connecte Google, son site se met a mesurer,
--  personne n'a touche a un fichier.
-- ===================================================================

-- Deux colonnes, rien d'autre. Un identifiant de mesure n'est pas un
-- secret : il figure en clair dans le code source de chaque page qui
-- l'utilise, chez Google comme partout ailleurs. Ce qui serait grave,
-- ce serait d'exposer profils_client en entier — d'ou la vue plutot
-- qu'une policy sur la table.
create or replace view mesure_publique as
select client_id, ga4_measurement_id
from profils_client
where ga4_measurement_id is not null;

-- La vue s'execute avec les droits de son proprietaire et contourne
-- donc la RLS de profils_client. C'est voulu et c'est borne : elle ne
-- peut renvoyer que ces deux colonnes, pour les seules lignes qui ont
-- un identifiant.
alter view mesure_publique set (security_invoker = false);

grant select on mesure_publique to anon, authenticated;


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------
--  Une ligne par client dont la propriete GA4 est reliee.

select client_id, ga4_measurement_id from mesure_publique;
