-- ===================================================================
--  DIAGNOSTIC : pourquoi le comptoir ne recoit pas de notification.
--
--  A lancer dans l'editeur SQL de Supabase. Ne modifie RIEN, ne fait
--  que lire. Chaque bloc repond a une question, dans l'ordre du
--  trajet d'une notification :
--
--     commande inseree  ->  trigger  ->  push-commande  ->  telephone
--
--  Le premier bloc qui repond << non >> est la panne. Inutile de lire
--  les suivants.
-- ===================================================================

-- -------------------------------------------------------------------
--  1. La commande de test est-elle bien arrivee en base ?
--
--  Si cette liste est vide, le probleme n'est pas la notification :
--  c'est la commande elle-meme qui n'est pas passee.
--  `statut` DOIT valoir 'recue' — le trigger ne se declenche que sur
--  celles-la.
-- -------------------------------------------------------------------
select id, date_creation, statut, nom_client, total
from commandes
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
order by date_creation desc
limit 5;

-- -------------------------------------------------------------------
--  2. Un telephone est-il vraiment abonne ?
--
--  Zero ligne = personne n'a d'abonnement enregistre, et aucune
--  notification ne peut partir, quoi qu'on fasse ailleurs. C'est le
--  cas si le bouton << Activer les alertes >> a ete touche mais que
--  l'enregistrement a echoue en silence.
--
--  `service` dit a qui appartient l'abonnement : Apple pour un iPhone
--  ou un iPad, Google pour un Android ou un Chrome de bureau.
-- -------------------------------------------------------------------
select
  cree_le,
  case
    when endpoint like '%push.apple.com%'      then 'Apple (iPhone / iPad)'
    when endpoint like '%fcm.googleapis.com%'  then 'Google (Android / Chrome)'
    when endpoint like '%mozilla%'             then 'Mozilla (Firefox)'
    when endpoint like '%windows.com%'         then 'Microsoft (Edge)'
    else 'autre'
  end as service,
  left(endpoint, 60) || '...' as debut_endpoint
from abonnements_push_resto
where client_id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b'
order by cree_le desc;

-- -------------------------------------------------------------------
--  3. Le declencheur existe-t-il, et porte-t-il le bon secret ?
--
--  `secret_encore_a_remplacer` DOIT valoir false. S'il vaut true, la
--  migration 19 a ete lancee sans remplacer REMPLACEZ_MOI : la
--  fonction repond 401 et jette la notification, sans que rien ne le
--  signale nulle part. C'est la panne la plus frequente ici.
-- -------------------------------------------------------------------
select
  exists(select 1 from pg_trigger where tgname = 'commande_push'
         and not tgisinternal)                          as trigger_pose,
  (select prosrc like '%REMPLACEZ_MOI%'
     from pg_proc where proname = 'notifier_push_nouvelle_commande')
                                                        as secret_encore_a_remplacer,
  exists(select 1 from pg_extension where extname = 'pg_net')
                                                        as pg_net_installe;

-- -------------------------------------------------------------------
--  4. Qu'a repondu la fonction push-commande ?
--
--  C'est la reponse HTTP reelle, enregistree par pg_net. Elle tranche
--  entre << le trigger n'a rien envoye >> et << il a envoye et c'est
--  parti a la poubelle >> :
--
--    aucune ligne  le trigger ne s'est pas declenche du tout
--    200           la fonction a accepte ; lire `envoyees` dans le
--                  corps : 0 veut dire aucun appareil abonne
--    401           mauvais secret (voir le bloc 3)
--    500           cles VAPID absentes cote fonction
-- -------------------------------------------------------------------
select
  r.created                       as moment,
  r.status_code                   as code_http,
  left(r.content, 300)            as reponse
from net._http_response r
order by r.created desc
limit 10;

-- ===================================================================
--  CE QU'IL FAUT FAIRE SELON LE RESULTAT
--
--  Bloc 2 vide
--     Le telephone n'est pas abonne. Rouvrir l'ecran du comptoir
--     DEPUIS L'ICONE de l'ecran d'accueil (pas Safari), toucher
--     << Activer les alertes >>, accepter, puis relancer ce bloc 2 :
--     une ligne Apple doit apparaitre.
--
--  Bloc 3 : secret_encore_a_remplacer = true
--     Rejouer la migration 19 en remplacant REMPLACEZ_MOI par la
--     valeur de cles-push/secret-trigger.txt.
--
--  Bloc 4 : code 401
--     Meme chose : le secret du trigger et celui de la fonction ne
--     sont pas d'accord.
--
--  Bloc 4 : code 500
--     Les cles VAPID manquent cote fonction :
--     npx supabase secrets set VAPID_PUBLIC_KEY=... VAPID_PRIVATE_KEY=...
--     (valeurs dans cles-push/vapid.txt)
--
--  Bloc 4 : code 200 avec "envoyees":0
--     La fonction n'a trouve aucun abonnement : retour au bloc 2.
--
--  Bloc 4 : code 200 avec "envoyees":1 et toujours rien sur le
--  telephone
--     La notification est partie chez Apple. Reste alors le
--     telephone : mode Concentration ou Ne pas deranger actif,
--     ou l'application retiree de l'ecran d'accueil depuis.
-- ===================================================================
