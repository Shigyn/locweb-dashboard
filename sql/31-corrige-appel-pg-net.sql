-- ===================================================================
--  CORRECTIF : le declencheur des notifications appelait une fonction
--  qui n'existe pas.
--
--  La migration 19 ecrit `extensions.net.http_post(...)`. Postgres lit
--  ce chemin a trois niveaux comme BASE.SCHEMA.FONCTION : il cherche
--  donc une base de donnees nommee `extensions`, et repond
--
--      0A000: cross-database references are not implemented
--
--  pg_net installe ses fonctions dans le schema `net`, quel que soit
--  le schema demande a `create extension` — le bon chemin est donc
--  `net.http_post(...)`, a deux niveaux.
--
--  POURQUOI PERSONNE NE L'A VU. L'erreur etait levee a chaque
--  commande, puis avalee par le `exception when others` de la
--  migration 19 — qui est la pour une bonne raison : une notification
--  ratee ne doit jamais empecher une commande d'etre enregistree. Le
--  resultat est qu'on avait un declencheur pose, un secret correct,
--  pg_net installe, et zero notification, sans une trace nulle part.
--  Constate le 2026-09-09 sur KSM : commande bien recue au comptoir
--  (le son de l'ecran l'a signalee), aucune notification sur les deux
--  appareils abonnes.
--
--  CE SCRIPT NE DEMANDE AUCUN SECRET. Il relit celui deja pose dans
--  la fonction existante et le reecrit tel quel : pas de valeur a
--  recopier, donc pas de faute de frappe possible.
--
--  Pas de `format()` ici, volontairement : le corps de la fonction
--  contient des `%` (le `raise warning` final), et `format()` les prend
--  pour des specificateurs. On concatene et on passe le secret par
--  `quote_literal`, qui fait le meme travail sans toucher au reste.
-- ===================================================================

do $do$
declare
  secret_actuel text;
begin
  select substring(prosrc from 'secret_notif constant text := ''([^'']*)''')
    into secret_actuel
    from pg_proc
   where proname = 'notifier_push_nouvelle_commande';

  if secret_actuel is null then
    raise exception
      'Secret introuvable dans la fonction existante. Lancez d''abord la migration 19.';
  end if;

  if secret_actuel = 'REMPLACEZ_MOI' then
    raise exception
      'La migration 19 a ete lancee sans remplacer REMPLACEZ_MOI. Corrigez-la d''abord.';
  end if;

  execute
    $partie1$
    create or replace function notifier_push_nouvelle_commande()
    returns trigger
    language plpgsql
    security definer
    -- `net` ajoute au chemin : c'est la que pg_net pose ses fonctions.
    set search_path = public, net, extensions
    as $corps$
    declare
      url_fonction constant text :=
        'https://ibqawtgnucakzdldnitj.supabase.co/functions/v1/push-commande';
      secret_notif constant text := $partie1$
    || quote_literal(secret_actuel) ||
    $partie2$;
    begin
      -- On ne notifie que l'arrivee. Les changements de statut viennent
      -- du comptoir lui-meme : le prevenir de ce qu'il vient de faire
      -- n'a aucun sens.
      if new.statut is distinct from 'recue' then
        return new;
      end if;

      -- Deux niveaux et non trois : `net.http_post`, jamais
      -- `extensions.net.http_post`.
      perform net.http_post(
        url     := url_fonction,
        headers := jsonb_build_object(
                     'Content-Type',   'application/json',
                     'x-notif-secret', secret_notif
                   ),
        body    := jsonb_build_object('record', to_jsonb(new)),
        timeout_milliseconds := 5000
      );
      return new;
    exception when others then
      -- On continue d'avaler l'erreur — une commande doit s'enregistrer
      -- meme si la notification echoue — mais elle remonte maintenant
      -- dans les journaux Postgres avec son code, la ou elle etait
      -- totalement invisible.
      raise warning 'push commande non envoyee : % (%)', sqlerrm, sqlstate;
      return new;
    end;
    $corps$;
    $partie2$;

  raise notice 'Declencheur corrige : net.http_post au lieu de extensions.net.http_post.';
end
$do$;

-- Le declencheur pointe deja sur cette fonction ; `create or replace`
-- suffit. On le repose quand meme, au cas ou la 19 n'aurait pas ete
-- jouee en entier.
drop trigger if exists commande_push on commandes;
create trigger commande_push
  after insert on commandes
  for each row
  execute function notifier_push_nouvelle_commande();

-- -------------------------------------------------------------------
--  VERIFICATION. `ancien_chemin_encore_present` doit valoir false.
-- -------------------------------------------------------------------
--  On cherche l'APPEL (`perform ...`) et non la chaine seule : le corps
--  cite `extensions.net.http_post` dans un commentaire, pour dire ce
--  qu'il ne faut pas ecrire. Un `like` sur la chaine nue tombait
--  dessus et annoncait une correction ratee alors qu'elle etait
--  passee. Erreur commise puis corrigee le 2026-09-09.
select
  prosrc like '%perform net.http_post%'             as bon_appel_present,
  prosrc like '%perform extensions.net.http_post%'  as mauvais_appel_present,
  prosrc like '%search_path = public, net%'         as chemin_de_recherche_ok
from pg_proc where proname = 'notifier_push_nouvelle_commande';
