-- ===================================================================
--  Le restaurateur peut lire ses commandes depuis son espace client.
--
--  Jusqu'ici `commandes` n'avait AUCUNE policy de lecture : seules les
--  fonctions serveur y accedaient, avec la cle de service. C'etait le
--  bon choix pour l'ecran du comptoir, qui n'a pas de compte et se
--  protege par un code partage.
--
--  Mais le tableau de bord, lui, a un compte. Un restaurateur connecte
--  a son espace y voyait << Aucune demande recue >> pour toujours : la
--  page lit `leads`, c'est-a-dire les formulaires de contact, et un
--  snack n'en a pas. Ce qu'il recoit, ce sont des COMMANDES, et rien
--  ne les lui montrait.
--
--  On reprend mot pour mot le motif deja utilise pour `leads` dans la
--  migration 01 : chacun ne voit que les lignes de SON client_id, et
--  l'operateur voit tout. Aucune invention, aucune exception.
--
--  LECTURE SEULE, et c'est deliberе. Le statut d'une commande se
--  change au comptoir, sur l'ecran de service, par quelqu'un qui a le
--  plat sous les yeux. Rien ne justifie de pouvoir le faire depuis le
--  tableau de bord, et une commande passee a << prete >> par erreur
--  depuis un telephone en salle, c'est un client qui attend pour rien.
-- ===================================================================

drop policy if exists "Lecture des commandes par leur proprietaire" on commandes;
create policy "Lecture des commandes par leur proprietaire"
  on commandes for select
  using (
    client_id = (select id from clients where auth_user_id = auth.uid())
  );

drop policy if exists "Operateur lit toutes les commandes" on commandes;
create policy "Operateur lit toutes les commandes"
  on commandes for select using (est_operateur());

-- Les lignes d'une commande suivent la meme regle : sans elles, on
-- afficherait un total sans savoir ce qu'il y a dedans.
drop policy if exists "Lecture des articles par le proprietaire" on commande_articles;
create policy "Lecture des articles par le proprietaire"
  on commande_articles for select
  using (
    commande_id in (
      select id from commandes
      where client_id = (select id from clients where auth_user_id = auth.uid())
    )
  );

drop policy if exists "Operateur lit tous les articles" on commande_articles;
create policy "Operateur lit tous les articles"
  on commande_articles for select using (est_operateur());

-- -------------------------------------------------------------------
--  VERIFICATION. Les quatre policies doivent apparaitre.
-- -------------------------------------------------------------------
select tablename, policyname, cmd
from pg_policies
where tablename in ('commandes', 'commande_articles')
order by tablename, policyname;
