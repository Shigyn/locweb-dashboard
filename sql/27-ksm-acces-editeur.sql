-- ===================================================================
--  KSM Burger — verifier (et ouvrir) l'acces editeur du compte
--
--  POURQUOI CE FICHIER. L'editeur n'affiche la section « Ma carte »
--  que si DEUX conditions sont reunies, et elles sont dans deux
--  tables differentes :
--
--   1. `clients.acces_client = 'complet'`
--      C'est le verrou principal. Dans `vue-monsite.js`, les produits
--      ne sont meme pas CHARGES autrement :
--          client.acces_client === 'complet'
--            ? charger('produits', ...)
--            : Promise.resolve([])
--      Avec 'essentiel', Kassim ne voit que ses horaires, son bas de
--      page et son contact. Avec 'aucun', il ne voit rien du tout.
--
--   2. `profils_client.secteur = 'restaurateur'`
--      Celui-la ne verrouille rien, il nomme. Il fait ecrire
--      « Ma carte » et « + Ajouter un plat » au lieu de « Produits et
--      tarifs » et « + Ajouter un produit », et il restreint les
--      sections de texte a Hero / Services / Horaires — les neuf
--      sections du modele artisan (A propos, Engagement, Expertise...)
--      ne bougent jamais chez un restaurateur et noyaient les utiles.
--
--  A JOUER EN DEUX TEMPS : le SELECT d'abord, pour voir ou on en est.
--  Les UPDATE ensuite, seulement si le SELECT montre autre chose que
--  'complet' et 'restaurateur'.
-- ===================================================================

-- -------------------------------------------------------------------
--  1. ETAT ACTUEL — a lire avant de toucher a quoi que ce soit
-- -------------------------------------------------------------------
select c.nom_site,
       c.acces_client,                    --  attendu : complet
       p.secteur,                         --  attendu : restaurateur
       c.auth_user_id is not null as compte_relie,
       c.email
  from clients c
  left join profils_client p on p.client_id = c.id
 where c.id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';


-- -------------------------------------------------------------------
--  2. OUVRIR L'ACCES COMPLET
--
--     A jouer seulement si la colonne `acces_client` ci-dessus ne dit
--     pas deja 'complet'.
-- -------------------------------------------------------------------
update clients
   set acces_client = 'complet'
 where id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';


-- -------------------------------------------------------------------
--  3. DIRE QUE C'EST UN RESTAURANT
--
--     `upsert` plutot qu'un simple update : si Kassim n'a jamais fini
--     l'onboarding, sa ligne de profil n'existe pas, et un update ne
--     ferait rien sans le dire. La cle de conflit est `client_id`,
--     celle qu'utilise deja `majProfil` dans l'editeur.
--
--     CE BLOC EST COSMETIQUE : il ne change que des libelles. S'il
--     echoue (une colonne obligatoire de `profils_client` que je ne
--     peux pas lire d'ici), l'acces complet du bloc 2 est deja pose et
--     la carte est modifiable — on lira juste « Produits et tarifs »
--     au lieu de « Ma carte ». Ne pas bloquer dessus.
-- -------------------------------------------------------------------
insert into profils_client (client_id, secteur)
values ('dff6ff69-5c68-4ee3-b2f1-21da6304ff5b', 'restaurateur')
on conflict (client_id) do update set secteur = 'restaurateur';


-- -------------------------------------------------------------------
--  4. RELIRE — les deux colonnes doivent afficher les valeurs attendues
-- -------------------------------------------------------------------
select c.nom_site, c.acces_client, p.secteur,
       c.auth_user_id is not null as compte_relie
  from clients c
  left join profils_client p on p.client_id = c.id
 where c.id = 'dff6ff69-5c68-4ee3-b2f1-21da6304ff5b';
