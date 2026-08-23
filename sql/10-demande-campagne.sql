-- ===================================================================
--  10 — Le client peut DEMANDER une campagne.
--
--  A executer apres 08.
--
--  Bug : `campagnes` n'avait qu'une policy de lecture pour le client.
--  Le bouton "Envoyer ma demande" de l'assistant Acquisition finissait
--  donc systematiquement sur "Envoi impossible", pour tout le monde,
--  depuis toujours. Aucune demande n'est jamais arrivee.
-- ===================================================================

-- Le client cree la demande, il ne cree pas la campagne. Le `with check`
-- verrouille deux choses a la fois :
--   - la ligne lui appartient ;
--   - le statut part obligatoirement a 'demandee'.
-- Sans la seconde condition, un client pourrait inserer une campagne
-- deja "en cours" et fausser le suivi de Nico.
drop policy if exists "Client demande une campagne" on campagnes;
create policy "Client demande une campagne"
  on campagnes for insert
  with check (
    client_id = (select id from clients where auth_user_id = auth.uid())
    and statut = 'demandee'
  );

-- Volontairement PAS de policy d'UPDATE ni de DELETE pour le client :
-- une fois la demande partie, elle appartient au suivi. Un client qui
-- veut changer son budget refait une demande ou nous appelle.


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------
--  Doit lister la policy d'insertion a cote de celle de lecture.

select policyname, cmd
from pg_policies
where tablename = 'campagnes'
order by policyname;
