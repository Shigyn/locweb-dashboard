-- Commandes a emporter : l'heure demandee par le client et l'heure
-- confirmee par le restaurant sont deux faits distincts.
--
-- Avant cette migration, les deux tenaient dans `adresse_livraison`,
-- une colonne inutilisee pour un retrait sur place. Ca marchait, mais
-- ca melangeait deux informations dans un champ qui porte le mauvais
-- nom, et le module Commandes du tableau de bord ne pourra rien en
-- faire de propre.
--
-- IMPORTANT — le code ne DEPEND pas de cette migration.
-- `create-commande-retrait` ecrit d'abord la commande sans ces
-- colonnes, puis tente de les remplir dans un second temps : si elles
-- n'existent pas encore, la tentative echoue en silence et la commande
-- est deja enregistree. `adresse_livraison` reste rempli dans tous les
-- cas et sert de secours a l'affichage.
--
-- La raison de cette prudence : une requete PostgREST qui cite une
-- seule colonne inexistante est rejetee EN ENTIER. Une commande perdue
-- parce qu'une migration n'etait pas passee, c'est un client qui
-- attend au comptoir un repas que personne ne prepare.

alter table commandes add column if not exists heure_demandee  text;
alter table commandes add column if not exists heure_confirmee text;

-- Le restaurant lit ses commandes par la fonction `restaurant-ksm`,
-- qui passe par la cle de service : aucune policy supplementaire n'est
-- necessaire ici, et on n'en ajoute pas. Un visiteur anonyme ne doit
-- toujours pas pouvoir lire la table.
