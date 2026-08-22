-- ===================================================================
--  Connexion OAuth Google reelle (Google Business Profile + GA4).
--
--  La table `connexions_google` stocke les jetons d'acces — ce sont des
--  identifiants sensibles au meme titre qu'un mot de passe, jamais
--  exposes a un navigateur. RLS est active mais AUCUNE policy n'est
--  posee pour `anon`/`authenticated` : ni le client, ni meme l'operateur
--  via la cle publique ne peuvent lire cette table. Seule la cle
--  service_role (utilisee exclusivement par l'Edge Function, jamais
--  cote navigateur) contourne RLS et peut y ecrire/lire.
-- ===================================================================

create table if not exists connexions_google (
  id             bigserial primary key,
  client_id      uuid not null references clients(id) on delete cascade,
  service        text not null,                    -- 'gbp' | 'ga4'
  access_token   text not null,
  refresh_token  text,
  expire_le      timestamptz,
  connecte_le    timestamptz not null default now(),
  unique (client_id, service)
);

alter table connexions_google enable row level security;
-- Volontairement aucune policy : personne via l'API publique (anon ou
-- authenticated) ne peut toucher cette table, quel que soit son role.

-- Ce que le client VOIT, c'est seulement s'il est connecte et depuis
-- quand — jamais le jeton lui-meme. `acces_google_business` existe deja
-- (auto-declaration manuelle) ; l'Edge Function la remplit desormais
-- elle-meme apres un vrai consentement OAuth. `acces_ga4` est nouvelle.
alter table profils_client add column if not exists acces_ga4 timestamptz;

-- Necessaire pour interroger l'API GA4 Data (differe du Measurement ID
-- G-XXXXX deja stocke dans ga4_measurement_id, qui sert au tag gtag.js
-- sur le site, pas a l'API). Admin GA4 -> Parametres de la propriete.
alter table profils_client add column if not exists ga4_property_id text;

