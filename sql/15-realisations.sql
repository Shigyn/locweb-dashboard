-- ===================================================================
--  15 — Chantiers : les photos avant / apres.
--
--  A executer apres 14.
--
--  Ce qu'un artisan a de plus convaincant, il l'a deja dans son
--  telephone. Une facade refaite, une salle de bain finie : la photo
--  vend mieux que n'importe quel texte, et il en prend tous les jours
--  sans que rien n'en arrive jamais sur son site.
--
--  Le but est qu'il photographie en partant du chantier et que ce soit
--  en ligne le soir meme, sans nous appeler et sans ouvrir un
--  ordinateur.
--
--  La photo « avant » est facultative : elle n'existe pas toujours, et
--  exiger la paire ferait perdre les trois quarts des publications.
-- ===================================================================

create table if not exists realisations (
  id           uuid primary key default gen_random_uuid(),
  client_id    uuid not null references clients(id) on delete cascade,
  titre        text,
  -- Ce qu'on a fait, en une phrase. Facultatif : un artisan qui doit
  -- rediger avant de publier ne publie pas.
  description  text,
  photo_avant  text,
  photo_apres  text not null,
  -- L'ordre d'affichage sur le site. Par defaut la plus recente
  -- d'abord, ce qui est presque toujours ce qu'on veut.
  ordre        int not null default 0,
  publiee      boolean not null default true,
  cree_le      timestamptz not null default now()
);

create index if not exists realisations_client on realisations(client_id, ordre desc, cree_le desc);

alter table realisations enable row level security;

-- Le client gere les siennes.
drop policy if exists "Client gere ses realisations" on realisations;
create policy "Client gere ses realisations" on realisations
  for all
  using (client_id in (select id from clients where auth_user_id = auth.uid()))
  with check (client_id in (select id from clients where auth_user_id = auth.uid()));

-- L'operateur voit et corrige tout, comme partout ailleurs.
drop policy if exists "Operateur gere toutes les realisations" on realisations;
create policy "Operateur gere toutes les realisations" on realisations
  for all using (est_operateur()) with check (est_operateur());

-- Le site public lit les chantiers publies. Meme logique que les
-- produits : la page est statique, elle interroge la base en anonyme.
drop policy if exists "Lecture publique des realisations publiees" on realisations;
create policy "Lecture publique des realisations publiees" on realisations
  for select to anon
  using (publiee = true);


-- -------------------------------------------------------------------
--  Verification
-- -------------------------------------------------------------------

select count(*) as chantiers from realisations;
