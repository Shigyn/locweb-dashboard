// ===================================================================
//  Console LocWeb — noyau.
//
//  Trois responsabilites, pas une de plus : ouvrir la session, garder
//  en memoire ce qui a deja ete charge, et poser la bonne vue dans la
//  page. Tout le rendu vit dans les modules `vue-*`.
// ===================================================================

import { $, h, vider, initiales, souffler } from './outils.js';
import * as D from './donnees.js';

/* ------------------------------------------------------------------
   Cache de session.

   Les listes clients, demandes et visites sont relues par presque
   toutes les vues. Les recharger a chaque navigation rendrait la
   console poussive pour rien : les donnees d'une console d'exploitation
   ne changent pas d'une seconde a l'autre. On garde donc en memoire, et
   on invalide explicitement apres chaque ecriture.
   ------------------------------------------------------------------ */
const cache = new Map();

export async function charger(cle, fabrique) {
  if (!cache.has(cle)) cache.set(cle, fabrique().catch((e) => { cache.delete(cle); throw e; }));
  return cache.get(cle);
}

export function oublier(prefixe = '') {
  for (const cle of [...cache.keys()]) {
    if (!prefixe || cle.startsWith(prefixe)) cache.delete(cle);
  }
}

export const etat = { operateur: null };

/* ------------------------------------------------------------------
   Theme
   ------------------------------------------------------------------ */

// Deux etats, pas trois : un interrupteur clair/sombre, pas un choix
// "systeme" qu'il faut d'abord comprendre. Premiere visite -> on suit
// quand meme la preference systeme une fois, puis l'operateur decide.
const NOMS_THEME = { clair: 'Clair', sombre: 'Sombre' };
const ICONES_THEME = {
  clair: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  sombre: '<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z"/>',
};

function appliquerTheme(t) {
  document.documentElement.dataset.theme = t;
  $('#libelle-theme').textContent = NOMS_THEME[t];
  const icone = $('#bt-theme .ic');
  if (icone) icone.innerHTML = ICONES_THEME[t];
  try { localStorage.setItem('locweb-theme', t); } catch { /* navigation privee */ }
}

appliquerTheme((() => {
  try {
    const enregistre = localStorage.getItem('locweb-theme');
    if (enregistre === 'clair' || enregistre === 'sombre') return enregistre;
  } catch { /* navigation privee */ }
  return matchMedia('(prefers-color-scheme: dark)').matches ? 'sombre' : 'clair';
})());

$('#bt-theme').addEventListener('click', () => {
  appliquerTheme(document.documentElement.dataset.theme === 'sombre' ? 'clair' : 'sombre');
});

/* ------------------------------------------------------------------
   Connexion
   ------------------------------------------------------------------ */

const ecranConnexion = $('#ecran-connexion');
const console_ = $('#console');
const erreurConnexion = $('#connexion-erreur');

$('#form-connexion').addEventListener('submit', async (e) => {
  e.preventDefault();
  const bouton = $('#bt-connexion');
  erreurConnexion.textContent = '';
  bouton.disabled = true;
  bouton.textContent = 'Connexion...';

  const erreur = await D.connexion($('#ident-email').value.trim(), $('#ident-mdp').value);

  bouton.disabled = false;
  bouton.textContent = 'Se connecter';

  if (erreur) {
    // Volontairement vague : distinguer "compte inconnu" de "mot de
    // passe faux" indiquerait a un inconnu quelles adresses existent.
    erreurConnexion.textContent = 'Identifiants incorrects.';
    return;
  }
  await entrer();
});

$('#bt-oubli').addEventListener('click', async () => {
  const email = $('#ident-email').value.trim();
  if (!email) { erreurConnexion.textContent = 'Renseignez votre adresse e-mail d abord.'; return; }
  await D.sb.auth.resetPasswordForEmail(email, { redirectTo: location.origin + location.pathname });
  erreurConnexion.textContent = '';
  souffler('Si ce compte existe, un lien vient de partir.', 'bien');
});

$('#bt-deconnexion').addEventListener('click', async () => {
  await D.deconnexion();
  oublier();
  location.reload();
});

async function entrer() {
  const op = await D.operateur();

  if (!op) {
    // Un compte client qui atterrit ici. RLS l'empecherait de voir quoi
    // que ce soit d'autre que son propre site, mais mieux vaut une
    // porte fermee proprement qu'une console vide et inexplicable.
    await D.deconnexion();
    erreurConnexion.textContent = "Ce compte n a pas acces a la console.";
    return;
  }

  etat.operateur = op;
  const nom = op.nom || op.email;
  $('#compte-nom').textContent = nom;
  $('#compte-mail').textContent = op.email || '';
  $('#compte-initiale').textContent = initiales(nom);

  ecranConnexion.style.display = 'none';
  console_.classList.add('visible');

  await router();
  rafraichirPastilles();
}

/* ------------------------------------------------------------------
   Routage

   Un hash, pas d'historique reconstruit a la main : le bouton retour du
   navigateur doit marcher, et une adresse doit pouvoir se coller dans
   un message.
   ------------------------------------------------------------------ */

const page = $('#page');
const barreGauche = $('#barre-gauche');
const barreDroite = $('#barre-droite');

const VUES = {
  'clients':      () => import('./vue-clients.js'),
  'client':       () => import('./vue-client.js'),
  'demandes':     () => import('./vue-demandes.js'),
  'performances': () => import('./vue-performances.js'),
  'campagnes':    () => import('./vue-campagnes.js'),
  'mots-cles':    () => import('./vue-mots-cles.js'),
};

export function aller(hash) { location.hash = hash; }

export function tete(titre, ...actions) {
  vider(barreGauche);
  vider(barreDroite);
  barreGauche.append(typeof titre === 'string' ? h('h1', titre) : titre);
  barreDroite.append(...actions.flat().filter(Boolean));
}

// Squelette plutot qu'un texte : la forme des cartes qui arrivent est
// deja visible pendant le chargement, l'oeil n'a rien a reapprendre
// quand les vraies donnees se posent dessus.
function chargement() {
  vider(page);
  page.append(
    h('div.synthese',
      h('div.squelette.squelette-mesure'), h('div.squelette.squelette-mesure'),
      h('div.squelette.squelette-mesure'), h('div.squelette.squelette-mesure')),
    h('div.squelette.squelette-ligne'),
    h('div.squelette.squelette-ligne'),
    h('div.squelette.squelette-ligne'),
  );
}

let jeton = 0;

async function router() {
  if (!etat.operateur) return;

  const [nom, ...args] = (location.hash.replace(/^#\/?/, '') || 'clients').split('/');
  const importer = VUES[nom] || VUES.clients;

  // Un jeton par navigation : si l'operateur reclique ailleurs pendant
  // qu'une vue charge, la vue lente ne doit pas ecraser la nouvelle en
  // arrivant apres coup.
  const mien = ++jeton;
  chargement();

  document.querySelectorAll('.rail-nav a[data-route]').forEach((a) => {
    const actif = a.dataset.route === nom || (nom === 'client' && a.dataset.route === 'clients');
    a.setAttribute('aria-current', actif ? 'page' : 'false');
  });

  try {
    const module = await importer();
    if (mien !== jeton) return;
    vider(page);
    await module.rendre(page, args);
  } catch (e) {
    if (mien !== jeton) return;
    console.error(e);
    vider(page);
    page.append(
      h('div.carte', h('div.carte-corps',
        h('p.mot', { 'data-ton': 'alerte' }, 'Impossible de charger cette page.'),
        h('p', { style: { color: 'var(--sourdine)', fontSize: '.85rem' } }, e?.message || String(e)),
        h('p', { style: { marginTop: '14px' } },
          h('button.bt.bt-plein', { onclick: () => { oublier(); router(); } }, 'Reessayer')),
      )),
    );
  }
}

addEventListener('hashchange', router);

/* ------------------------------------------------------------------
   Pastilles du rail : ce qui attend une action.
   ------------------------------------------------------------------ */

export async function rafraichirPastilles() {
  try {
    const [demandes, campagnes] = await Promise.all([
      charger('demandes', () => D.listerDemandes({})),
      charger('campagnes', () => D.listerCampagnes()),
    ]);
    poser('#pastille-demandes', demandes.filter((d) => (d.statut || 'nouvelle') === 'nouvelle').length);
    poser('#pastille-campagnes', campagnes.filter((c) => c.statut === 'demandee').length);
  } catch { /* le rail n'est pas critique : s'il echoue, la console marche quand meme */ }
}

function poser(sel, n) {
  const el = $(sel);
  if (!el) return;
  el.textContent = n > 99 ? '99+' : String(n);
  el.hidden = n === 0;
}

/* ------------------------------------------------------------------
   Demarrage
   ------------------------------------------------------------------ */

(async function demarrer() {
  if (await D.session()) await entrer();
  else ecranConnexion.style.display = 'grid';
})();
