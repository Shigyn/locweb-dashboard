-- ===================================================================
--  Prevenir le comptoir quand une commande arrive.
--
--  Le trou que ca bouche : jusqu'ici, l'ecran du comptoir devait etre
--  ouvert ET regarde. Tablette en veille, autre onglet, navigateur
--  ferme — la commande arrivait et personne ne le savait. Un client
--  attendait au comptoir un repas que personne n'avait commence.
--
--  Pourquoi un trigger et pas un appel depuis la page : la commande
--  est creee par une fonction serveur, mais c'est la LIGNE EN BASE qui
--  fait foi. Si elle existe, la notification part — meme si la
--  fonction a plante juste apres l'insert.
-- ===================================================================

-- AVANT DE LANCER : remplacer `REMPLACEZ_MOI` plus bas par la meme
-- valeur que celle deja utilisee dans la migration 14, c'est-a-dire le
-- secret PUSH_NOTIF_SECRET pose cote fonction.

create extension if not exists pg_net with schema extensions;

-- -------------------------------------------------------------------
--  Une table a part, et non `abonnements_push`.
--
--  Cette derniere appartient a l'espace client (admin.locweb.fr) : ses
--  abonnements sont lies a un compte authentifie, et ses notifications
--  ouvrent `/#/demandes`. Le comptoir, lui, n'a pas de compte — juste
--  un code partage — et ses notifications doivent ouvrir sa propre
--  page, sur un autre domaine. Melanger les deux enverrait le
--  restaurateur sur une adresse qui n'existe pas chez lui.
-- -------------------------------------------------------------------
create table if not exists abonnements_push_resto (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references clients(id) on delete cascade,
  endpoint   text not null unique,
  p256dh     text not null,
  auth       text not null,
  cree_le    timestamptz not null default now()
);

create index if not exists abonnements_push_resto_client
  on abonnements_push_resto(client_id);

-- Aucune policy : personne n'y accede depuis un navigateur. Seules les
-- fonctions serveur, avec la cle de service, lisent et ecrivent ici.
-- Un abonnement push est un jeton d'envoi — il ne doit pas etre
-- listable par un visiteur.
alter table abonnements_push_resto enable row level security;

-- -------------------------------------------------------------------
--  Le declencheur
-- -------------------------------------------------------------------
create or replace function notifier_push_nouvelle_commande()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  url_fonction constant text :=
    'https://ibqawtgnucakzdldnitj.supabase.co/functions/v1/push-commande';
  -- MEME VALEUR que dans la migration 14 et que le secret
  -- PUSH_NOTIF_SECRET pose cote fonction. Meme convention qu'en 14 :
  -- on remplace ici a la main avant de lancer le script.
  secret_notif constant text := 'REMPLACEZ_MOI';
begin
  -- On ne notifie que l'arrivee. Les changements de statut viennent du
  -- comptoir lui-meme : le prevenir de ce qu'il vient de faire n'a
  -- aucun sens.
  if new.statut is distinct from 'recue' then
    return new;
  end if;

  perform extensions.net.http_post(
    url     := url_fonction,
    headers := jsonb_build_object(
                 'Content-Type',     'application/json',
                 'x-notif-secret',   secret_notif
               ),
    body    := jsonb_build_object('record', to_jsonb(new)),
    -- pg_net poste en asynchrone : l'insertion de la commande n'attend
    -- pas l'envoi.
    timeout_milliseconds := 5000
  );
  return new;
exception when others then
  -- Une notification qui echoue ne doit JAMAIS empecher une commande
  -- d'etre enregistree. Le comptoir la verra a son prochain
  -- rafraichissement, dix secondes plus tard.
  raise warning 'push commande non envoyee : %', sqlerrm;
  return new;
end;
$$;

drop trigger if exists commande_push on commandes;
create trigger commande_push
  after insert on commandes
  for each row
  execute function notifier_push_nouvelle_commande();

-- -------------------------------------------------------------------
--  Le camion n'est pas concerne, et sans qu'on ait a l'ecrire.
--
--  Le trigger se declenche pour toute commande, mais `push-commande`
--  cherche des abonnements pour le `client_id` de la ligne. Le camion
--  n'en a aucun dans cette table : rien ne part. Aucune condition en
--  dur sur un identifiant, donc rien a maintenir le jour ou un second
--  restaurant arrive.
-- -------------------------------------------------------------------
