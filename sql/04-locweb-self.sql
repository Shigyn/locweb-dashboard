-- ===================================================================
--  Rattache le compte operateur de Nicolas (masia.nicolas.07@gmail.com)
--  au client "LocWeb" existant, pour qu'il puisse se connecter a
--  admin.locweb.fr avec le MEME email/mot de passe que la console et
--  arriver directement sur son propre tableau de bord client.
--
--  Un seul compte auth peut a la fois etre operateur (table `operateurs`)
--  ET etre lie a un client (`clients.auth_user_id`) — les deux systemes
--  sont independants, pas de conflit.
-- ===================================================================

update clients
set auth_user_id = (select id from auth.users where email = 'masia.nicolas.07@gmail.com')
where id = '948dd7fa-545d-42f4-bd45-22ca6066d578';

-- Verification
select id, nom_site, auth_user_id from clients where id = '948dd7fa-545d-42f4-bd45-22ca6066d578';


-- -------------------------------------------------------------------
--  Vrais identifiants Google Business Profile / GA4 pour LocWeb.
--
--  Ce ne sont PAS des secrets (un Location ID ou un ID de mesure GA4
--  sont deja visibles publiquement dans le code source de n'importe
--  quel site qui les utilise) — a la difference d'un Client Secret
--  OAuth, qui ne doit JAMAIS atterrir ici ni dans aucun fichier
--  cote client.
-- -------------------------------------------------------------------

alter table profils_client add column if not exists gbp_location_id text;
alter table profils_client add column if not exists ga4_measurement_id text;

insert into profils_client (client_id, gbp_location_id, ga4_measurement_id, date_maj)
values ('948dd7fa-545d-42f4-bd45-22ca6066d578', '16711969773629618707', 'G-V0BV2R07Q4', now())
on conflict (client_id) do update set
  gbp_location_id    = excluded.gbp_location_id,
  ga4_measurement_id = excluded.ga4_measurement_id,
  date_maj           = now();
