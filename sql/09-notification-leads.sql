-- ===================================================================
--  09 — Notification e-mail a chaque nouvelle demande.
--
--  A executer apres 08. AVANT de lancer ce fichier, remplacez la
--  valeur de `secret_notif` ligne ~40 par le meme secret que celui
--  pose cote fonction :
--      supabase secrets set LEAD_NOTIF_SECRET=<votre secret>
--
--  Pourquoi un trigger et pas un appel depuis le formulaire du site :
--  le formulaire tourne chez le visiteur. Un appel depuis la page
--  serait manquable (onglet ferme, reseau coupe) et surtout falsifiable.
--  Ici, si la ligne existe en base, l'e-mail part. Point.
-- ===================================================================

create extension if not exists pg_net with schema extensions;


-- -------------------------------------------------------------------
--  La fonction de trigger
-- -------------------------------------------------------------------

create or replace function notifier_nouveau_lead()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  -- Modifiez ces deux lignes, et elles seules.
  url_fonction constant text :=
    'https://ibqawtgnucakzdldnitj.supabase.co/functions/v1/lead-notification';
  secret_notif constant text := 'REMPLACEZ_MOI';
begin
  -- pg_net poste en asynchrone : l'insertion du lead n'attend pas
  -- l'envoi de l'e-mail. Un incident chez Resend ne doit jamais faire
  -- perdre une demande — c'est la donnee qui compte, pas la notification.
  perform extensions.net.http_post(
    url     := url_fonction,
    headers := jsonb_build_object(
                 'content-type',    'application/json',
                 'x-notif-secret',  secret_notif),
    body    := jsonb_build_object('record', to_jsonb(new)),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;


-- -------------------------------------------------------------------
--  Le branchement
-- -------------------------------------------------------------------

drop trigger if exists lead_notifie on leads;
create trigger lead_notifie
  after insert on leads
  for each row
  execute function notifier_nouveau_lead();


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------
--  1. Le trigger est bien pose :
select tgname, tgenabled from pg_trigger where tgname = 'lead_notifie';

--  2. Test grandeur nature — remplacez le nom du site, puis regardez
--     votre boite mail. Supprimez la ligne apres coup si besoin.
-- insert into leads (client_id, nom, telephone, email, ville, besoin, message)
-- values (
--   (select id from clients where nom_site = 'KSM Burger'),
--   'Test LocWeb', '06 12 34 56 78', 'test@exemple.fr', 'Beziers',
--   'Devis', 'Ceci est un test de notification.');

--  3. Les appels partis et leur reponse (pg_net garde un historique) :
-- select id, status_code, error_msg, created
-- from net._http_response order by created desc limit 5;
