-- ===================================================================
--  MEME BUG, AUTRE DECLENCHEUR : les notifications de prospects.
--
--  En corrigeant le declencheur des commandes (migration 31), on
--  s'apercoit que la migration 14 ecrit exactement la meme chose :
--
--      perform extensions.net.http_post(...)
--
--  Chemin a trois niveaux, lu par Postgres comme
--  BASE.SCHEMA.FONCTION, donc invalide. Le declencheur `lead_push`
--  sur `leads` leve une erreur a chaque nouveau prospect, et le
--  `exception when others` de la migration 14 l'avale sans rien
--  ecrire — comme pour les commandes.
--
--  Autrement dit : AUCUNE notification de nouveau prospect n'est
--  jamais partie depuis la mise en place. Un formulaire rempli sur un
--  site client n'a jamais fait sonner quoi que ce soit.
--
--  Meme methode qu'en 31 : on relit le secret deja pose, on ne
--  demande rien, on ne change que le chemin d'appel et on rend
--  l'erreur visible dans les journaux.
--
--  A NOTER : `lead-notification` a deja `verify_jwt = false` dans
--  config.toml. Ce declencheur-ci n'a donc pas le probleme de
--  passerelle rencontre sur push-commande.
-- ===================================================================

do $do$
declare
  secret_actuel text;
  src           text;
begin
  select prosrc,
         substring(prosrc from 'secret_notif constant text := ''([^'']*)''')
    into src, secret_actuel
    from pg_proc
   where proname = 'notifier_push_nouveau_lead';

  if src is null then
    raise notice 'Fonction notifier_push_nouveau_lead absente : rien a corriger.';
    return;
  end if;

  if secret_actuel is null or secret_actuel = 'REMPLACEZ_MOI' then
    raise exception
      'Secret absent ou non remplace dans notifier_push_nouveau_lead. Corrigez la migration 14 d''abord.';
  end if;

  if src not like '%extensions.net.http_post%' then
    raise notice 'Chemin deja correct : rien a faire.';
    return;
  end if;

  -- On ne reecrit pas la fonction de zero : on remplace le chemin dans
  -- son propre corps. Tout le reste — conditions, message, colonnes
  -- lues — reste exactement ce que la migration 14 avait pose, et on
  -- ne risque pas de perdre une particularite en la recopiant.
  execute 'create or replace function notifier_push_nouveau_lead() '
       || 'returns trigger language plpgsql security definer '
       || 'set search_path = public, net, extensions as '
       || quote_literal(replace(src, 'extensions.net.http_post', 'net.http_post'));

  raise notice 'Declencheur des prospects corrige : net.http_post.';
end
$do$;

-- -------------------------------------------------------------------
--  VERIFICATION. `mauvais_appel_present` doit valoir false.
-- -------------------------------------------------------------------
select
  proname                                           as fonction,
  prosrc like '%perform net.http_post%'             as bon_appel_present,
  prosrc like '%perform extensions.net.http_post%'  as mauvais_appel_present
from pg_proc
where proname in ('notifier_push_nouvelle_commande', 'notifier_push_nouveau_lead')
order by proname;
