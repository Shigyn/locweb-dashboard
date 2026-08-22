// ===================================================================
//  Acces aux donnees.
//
//  Tout ce qui parle a Supabase passe par ici. Les vues ne construisent
//  jamais une requete elles-memes : quand le schema bouge, il n'y a
//  qu'un fichier a relire.
// ===================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

export const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/* ---------- session ---------- */

export async function session() {
  const { data } = await sb.auth.getSession();
  return data.session;
}

export async function connexion(email, mdp) {
  const { error } = await sb.auth.signInWithPassword({ email, password: mdp });
  return error;
}

export async function deconnexion() {
  await sb.auth.signOut();
}

// Renvoie la ligne operateur, ou null si le compte n'en est pas un.
// C'est le seul controle d'entree de la console : un compte client qui
// se connecterait ici verrait une console vide de toute facon (RLS ne
// lui rend qu'un seul client), mais autant le dire clairement.
export async function operateur() {
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return null;
  const { data } = await sb
    .from('operateurs')
    .select('auth_user_id, nom')
    .eq('auth_user_id', user.id)
    .maybeSingle();
  return data ? { ...data, email: user.email } : null;
}

/* ---------- clients ---------- */

export async function listerClients() {
  const { data, error } = await sb
    .from('clients')
    .select('id, nom_site, domaine, metier, ville, code_postal, telephone, email, formule, tarif_mensuel, statut, acces_client, date_mise_en_ligne, notes')
    .order('nom_site');
  if (error) throw error;
  return data || [];
}

export async function lireClient(id) {
  const { data, error } = await sb
    .from('clients')
    .select('*')
    .eq('id', id)
    .single();
  if (error) throw error;
  return data;
}

export async function majClient(id, champs) {
  const { error } = await sb.from('clients').update(champs).eq('id', id);
  if (error) throw error;
}

/* ---------- contenu ---------- */

export async function lireContenu(clientId) {
  const { data, error } = await sb
    .from('contenu_site')
    .select('id, cle_bloc, valeur, valeur_brouillon, type, date_maj')
    .eq('client_id', clientId)
    .order('cle_bloc');
  if (error) throw error;
  return data || [];
}

// Ecrire un brouillon, jamais la valeur publiee. Remettre le brouillon
// a la valeur en ligne revient a annuler la modification : on stocke
// alors NULL plutot qu'une copie, pour que le compteur de modifications
// en attente reste exact.
export async function ecrireBrouillon(ligneId, brouillon, valeurEnLigne) {
  const identique = (brouillon ?? '') === (valeurEnLigne ?? '');
  const { error } = await sb
    .from('contenu_site')
    .update({ valeur_brouillon: identique ? null : brouillon, date_maj: new Date().toISOString() })
    .eq('id', ligneId);
  if (error) throw error;
  return identique;
}

// Passe en ligne tout ce qui est en attente pour ce client, d'un bloc.
export async function publier(clientId) {
  const { data, error } = await sb.rpc('publier_client', { p_client_id: clientId });
  if (error) throw error;
  return data;
}

// Combien de modifications attendent d'etre publiees, par client.
// L'index partiel `idx_contenu_brouillon` ne couvre que les lignes
// concernees : meme avec des milliers de zones, cette requete ne lit
// que celles qui ont un brouillon.
export async function brouillonsEnAttente() {
  const { data, error } = await sb
    .from('contenu_site')
    .select('client_id')
    .not('valeur_brouillon', 'is', null);
  if (error) throw error;
  const par = new Map();
  for (const l of data || []) par.set(l.client_id, (par.get(l.client_id) || 0) + 1);
  return par;
}

export async function annulerBrouillons(clientId) {
  const { error } = await sb
    .from('contenu_site')
    .update({ valeur_brouillon: null })
    .eq('client_id', clientId)
    .not('valeur_brouillon', 'is', null);
  if (error) throw error;
}

/* ---------- demandes ---------- */

export async function listerDemandes({ clientId = null, limite = 200 } = {}) {
  let q = sb
    .from('leads')
    .select('id, client_id, nom, telephone, email, ville, besoin, message, statut, note_interne, date_creation')
    .order('date_creation', { ascending: false })
    .limit(limite);
  if (clientId) q = q.eq('client_id', clientId);
  const { data, error } = await q;
  if (error) throw error;
  return data || [];
}

export async function majDemande(id, champs) {
  if (champs.statut && champs.statut !== 'nouvelle') {
    champs.date_traitement = new Date().toISOString();
  }
  const { error } = await sb.from('leads').update(champs).eq('id', id);
  if (error) throw error;
}

/* ---------- visites ---------- */

export async function listerVisites({ clientId = null, jours = 30 } = {}) {
  const depuis = new Date(Date.now() - jours * 864e5).toISOString();
  let q = sb
    .from('visites')
    .select('client_id, chemin, referent, appareil, horodatage')
    .gte('horodatage', depuis)
    .order('horodatage', { ascending: false })
    .limit(5000);
  if (clientId) q = q.eq('client_id', clientId);
  const { data, error } = await q;
  if (error) throw error;
  return data || [];
}

/* ---------- campagnes ---------- */

export async function listerCampagnes(clientId = null) {
  let q = sb
    .from('campagnes')
    .select('*')
    .order('date_creation', { ascending: false });
  if (clientId) q = q.eq('client_id', clientId);
  const { data, error } = await q;
  if (error) throw error;
  return data || [];
}

export async function creerCampagne(campagne) {
  const { data, error } = await sb.from('campagnes').insert(campagne).select().single();
  if (error) throw error;
  return data;
}

export async function majCampagne(id, champs) {
  const { error } = await sb
    .from('campagnes')
    .update({ ...champs, date_maj: new Date().toISOString() })
    .eq('id', id);
  if (error) throw error;
}

export async function supprimerCampagne(id) {
  const { error } = await sb.from('campagnes').delete().eq('id', id);
  if (error) throw error;
}

/* ---------- profil client ---------- */

export async function lireProfil(clientId) {
  const { data } = await sb
    .from('profils_client')
    .select('*')
    .eq('client_id', clientId)
    .maybeSingle();
  return data;
}

export async function majProfil(clientId, champs) {
  const { error } = await sb
    .from('profils_client')
    .upsert({ client_id: clientId, ...champs, date_maj: new Date().toISOString() });
  if (error) throw error;
}
