-- ===================================================================
--  16 — Search Console : la propriete verifiee du client.
--
--  A executer apres 15.
--
--  Search Console repond a ce qu'Analytics ne peut pas voir : ce qui
--  se passe AVANT l'arrivee sur le site. Les mots reellement tapes, le
--  nombre d'apparitions dans les resultats, la position par requete.
--
--  Un site peut apparaitre 800 fois et n'etre clique que 25 fois :
--  Analytics affiche « 25 visiteurs » et laisse conclure qu'il n'y a
--  pas de demande, alors que le probleme est le titre affiche dans
--  Google. Ce sont deux problemes opposes, et un seul des deux se voit
--  sans Search Console.
--
--  `search_console_site` porte l'URL de la propriete telle que Google
--  la nomme — soit `https://exemple.fr/` (avec le slash final,
--  obligatoire), soit `sc-domain:exemple.fr` pour une propriete de
--  domaine. Elle se remplit seule a la connexion quand une seule
--  propriete verifiee correspond au domaine du client.
-- ===================================================================

alter table profils_client
  add column if not exists search_console_site text,
  -- Utile pour dire au client « depuis le 12 mars » plutot que de
  -- laisser croire que les chiffres couvrent toute la vie du site :
  -- Search Console ne remonte jamais avant la verification.
  add column if not exists search_console_depuis date;

comment on column profils_client.search_console_site is
  'Propriete Search Console verifiee : https://exemple.fr/ ou sc-domain:exemple.fr. Remplie automatiquement a la connexion Google quand une seule propriete correspond.';


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------

select client_id, search_console_site, search_console_depuis from profils_client;
