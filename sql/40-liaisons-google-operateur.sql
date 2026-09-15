-- ===================================================================
--  Liaisons Google reservees a l'operateur (2026-09-15).
--
--  Constate sur l'espace KSM : le compte Google branche etait celui de
--  LocWeb. L'ecran Connexions listait donc TOUTES les proprietes
--  Analytics et fiches de l'agence, et la policy « Client gere son
--  profil » laissait le client en choisir une (ou taper un ID a la
--  main). ga4-donnees / gbp-donnees lisaient ensuite ces chiffres avec
--  le jeton de l'agence : un client pouvait afficher les statistiques
--  d'un autre client.
--
--  Desormais seuls l'operateur et le serveur (cle de service :
--  auth.uid() nul, ex. oauth-google-echange qui pose l'ID quand il n'y
--  a qu'un choix) peuvent poser ou changer ces quatre colonnes.
-- ===================================================================

create or replace function public.garde_liaisons_google()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or est_operateur() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.ga4_property_id is not null or new.ga4_measurement_id is not null
       or new.gbp_location_id is not null or new.search_console_site is not null then
      raise exception 'Liaison Google reservee a LocWeb.' using errcode = '42501';
    end if;
  elsif new.ga4_property_id is distinct from old.ga4_property_id
     or new.ga4_measurement_id is distinct from old.ga4_measurement_id
     or new.gbp_location_id is distinct from old.gbp_location_id
     or new.search_console_site is distinct from old.search_console_site then
    raise exception 'Liaison Google reservee a LocWeb.' using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists garde_liaisons_google on profils_client;
create trigger garde_liaisons_google
  before insert or update on profils_client
  for each row execute function public.garde_liaisons_google();
