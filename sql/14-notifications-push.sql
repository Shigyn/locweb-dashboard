-- ===================================================================
--  14 — Notification push a chaque nouvelle demande.
--
--  A executer apres 13.
--
--  Le probleme : un artisan sur un toit ne consulte pas un tableau de
--  bord. Une demande vue trois jours plus tard est un chantier perdu,
--  et c'est precisement le moment ou il se demande a quoi sert son
--  abonnement.
--
--  Pourquoi un trigger et pas un appel depuis le formulaire du site :
--  le formulaire tourne chez le visiteur. Un appel depuis la page
--  serait manquable (onglet ferme, reseau coupe) et surtout
--  falsifiable. Ici, si la ligne existe en base, la notification part.
--
--  Independant de la migration 09 (e-mail) : les deux peuvent coexister
--  ou vivre seules. Le push ne coute rien et ne depend d'aucun
--  prestataire, contrairement a l'e-mail qui attend une cle Resend.
-- ===================================================================

create extension if not exists pg_net with schema extensions;


-- -------------------------------------------------------------------
--  Les abonnements
-- -------------------------------------------------------------------
--  Une ligne par appareil, pas par client : le meme artisan peut avoir
--  l'application sur son telephone et sur son ordinateur, et vouloir
--  etre prevenu sur les deux.

create table if not exists abonnements_push (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid not null references clients(id) on delete cascade,
  endpoint    text not null unique,
  p256dh      text not null,
  auth        text not null,
  agent       text,
  cree_le     timestamptz not null default now(),
  -- Un navigateur peut revoquer un abonnement sans prevenir. On note
  -- l'echec plutot que de supprimer tout de suite : deux envois rates
  -- d'affilee peuvent venir d'un telephone eteint.
  echecs      int not null default 0,
  dernier_ok  timestamptz
);

create index if not exists abonnements_push_client on abonnements_push(client_id);

alter table abonnements_push enable row level security;

drop policy if exists "Client gere ses propres abonnements" on abonnements_push;
create policy "Client gere ses propres abonnements" on abonnements_push
  for all
  using (client_id in (select id from clients where auth_user_id = auth.uid()))
  with check (client_id in (select id from clients where auth_user_id = auth.uid()));


-- -------------------------------------------------------------------
--  Le declencheur
-- -------------------------------------------------------------------
--  AVANT DE LANCER : remplacez `secret_notif` par la meme valeur que
--  celle posee cote fonction :
--      supabase secrets set PUSH_NOTIF_SECRET=<votre secret>

create or replace function notifier_push_nouveau_lead()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  url_fonction constant text :=
    'https://ibqawtgnucakzdldnitj.supabase.co/functions/v1/push-envoi';
  secret_notif constant text := 'REMPLACEZ_MOI';
begin
  -- pg_net poste en asynchrone : l'insertion de la demande n'attend pas
  -- l'envoi. Un incident cote push ne doit jamais faire perdre une
  -- demande — c'est la donnee qui compte, pas la notification.
  perform extensions.net.http_post(
    url     := url_fonction,
    headers := jsonb_build_object(
                 'content-type',   'application/json',
                 'x-notif-secret', secret_notif),
    body    := jsonb_build_object('record', to_jsonb(new)),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

drop trigger if exists lead_push on leads;
create trigger lead_push
  after insert on leads
  for each row
  execute function notifier_push_nouveau_lead();


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------

select count(*) as abonnements from abonnements_push;
