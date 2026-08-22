// ===================================================================
//  Petits outils communs.
//
//  Le point important est `esc` et l'usage systematique de textContent :
//  tout ce qui s'affiche ici vient de la base, donc d'un formulaire
//  public (les demandes de devis sont remplies par des inconnus). Une
//  seule concatenation dans innerHTML suffirait a executer leur code
//  dans la console. On ne prend pas ce risque : le HTML est construit,
//  jamais concatene avec des donnees.
// ===================================================================

export const $  = (sel, sous = document) => sous.querySelector(sel);
export const $$ = (sel, sous = document) => [...sous.querySelectorAll(sel)];

export function esc(v) {
  return String(v ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

/* Constructeur d'element minimal.
   h('div.carte', {onclick: f}, 'texte', h('span', 'autre'))
   Les chaines passees en enfant deviennent du texte, jamais du HTML. */
// document.createElement('svg') ne cree PAS un vrai element SVG (mauvais
// espace de noms) : la balise reste opaque, invisible, et innerHTML dessus
// ne dessine rien. Il faut createElementNS. Une fois l'element svg lui-meme
// correctement namespace, y injecter du balisage par innerHTML (voir 'html'
// plus bas) fonctionne normalement pour ses enfants (path, circle...).
const NS_SVG = 'http://www.w3.org/2000/svg';

export function h(spec, ...reste) {
  const [balise, ...classes] = spec.split('.');
  const estSvg = balise === 'svg';
  const el = estSvg ? document.createElementNS(NS_SVG, 'svg') : document.createElement(balise || 'div');
  if (classes.length) {
    if (estSvg) el.setAttribute('class', classes.join(' '));
    else el.className = classes.join(' ');
  }

  let enfants = reste;
  if (reste[0] && typeof reste[0] === 'object' && !(reste[0] instanceof Node) && !Array.isArray(reste[0])) {
    const attrs = reste[0];
    enfants = reste.slice(1);
    for (const [k, v] of Object.entries(attrs)) {
      if (v === null || v === undefined || v === false) continue;
      if (k === 'html') el.innerHTML = v;                  // seulement pour du balisage ecrit ici
      else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
      else if (k === 'style' && typeof v === 'object') Object.assign(el.style, v);
      // Sur un element SVG, les reflexions IDL (viewBox, preserveAspectRatio...)
      // ne sont pas de simples chaines assignables : toujours passer par
      // setAttribute plutot que par la propriete JS.
      else if (!estSvg && k in el && k !== 'list' && typeof v !== 'boolean') el[k] = v;
      else el.setAttribute(k, v === true ? '' : v);
    }
  }

  for (const enfant of enfants.flat(4)) {
    if (enfant === null || enfant === undefined || enfant === false) continue;
    el.append(enfant instanceof Node ? enfant : document.createTextNode(String(enfant)));
  }
  return el;
}

export function vider(el) { while (el.firstChild) el.firstChild.remove(); }

/* ---------- formats ---------- */

const JOURS = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
const MOIS  = ['janv.', 'fevr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'aout', 'sept.', 'oct.', 'nov.', 'dec.'];

export function dateCourte(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return `${d.getDate()} ${MOIS[d.getMonth()]}`;
}

export function dateLongue(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return `${JOURS[d.getDay()]} ${d.getDate()} ${MOIS[d.getMonth()]} ${d.getFullYear()}, ${String(d.getHours()).padStart(2, '0')}h${String(d.getMinutes()).padStart(2, '0')}`;
}

// "il y a 3 jours" — plus parlant qu'une date quand on scanne une liste
// pour reperer ce qui traine.
export function depuis(iso) {
  if (!iso) return '—';
  const s = (Date.now() - new Date(iso)) / 1000;
  if (s < 90) return "a l'instant";
  if (s < 5400) return `il y a ${Math.round(s / 60)} min`;
  if (s < 79200) return `il y a ${Math.round(s / 3600)} h`;
  const j = Math.round(s / 86400);
  if (j < 31) return `il y a ${j} j`;
  if (j < 365) return `il y a ${Math.round(j / 30)} mois`;
  return `il y a ${Math.round(j / 365)} an${j >= 730 ? 's' : ''}`;
}

export function euros(n) {
  if (n === null || n === undefined || n === '') return '—';
  return Number(n).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR', maximumFractionDigits: Number.isInteger(+n) ? 0 : 2 });
}

export function nombre(n) {
  return Number(n || 0).toLocaleString('fr-FR');
}

// Sans accent, sans ponctuation : sert aux mots-cles et aux recherches.
export function aplati(s) {
  return String(s ?? '')
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

export function initiales(s) {
  const m = aplati(s).split(' ').filter(Boolean);
  return ((m[0]?.[0] || '') + (m[1]?.[0] || '')).toUpperCase() || '?';
}

/* ---------- etats ---------- */

export const ETATS_DEMANDE = {
  nouvelle:     { libelle: 'Nouvelle',      ton: 'action' },
  vue:          { libelle: 'Vue',           ton: '' },
  devis_envoye: { libelle: 'Devis envoye',  ton: 'veille' },
  gagnee:       { libelle: 'Gagnee',        ton: 'bien' },
  perdue:       { libelle: 'Perdue',        ton: '' },
  indesirable:  { libelle: 'Indesirable',   ton: '' },
};

export const ETATS_CLIENT = {
  prospect:        { libelle: 'Prospect',        ton: '' },
  en_construction: { libelle: 'En construction', ton: 'veille' },
  actif:           { libelle: 'Actif',           ton: 'bien' },
  suspendu:        { libelle: 'Suspendu',        ton: 'alerte' },
  resilie:         { libelle: 'Resilie',         ton: '' },
};

export const ETATS_CAMPAGNE = {
  demandee:       { libelle: 'Demandee',       ton: 'action' },
  en_preparation: { libelle: 'En preparation', ton: 'veille' },
  active:         { libelle: 'Active',         ton: 'bien' },
  en_pause:       { libelle: 'En pause',       ton: '' },
  terminee:       { libelle: 'Terminee',       ton: '' },
};

export function pastilleEtat(cle, table) {
  const e = table[cle] || { libelle: cle || '—', ton: '' };
  return h('span.etat', { 'data-ton': e.ton || null }, e.libelle);
}

/* ---------- fenetres de dates ---------- */

export function jourDe(iso) { return new Date(iso).toISOString().slice(0, 10); }

// Les n derniers jours, du plus ancien au plus recent — sert de base a
// tout regroupement "par jour" (graphes, comptages).
export function joursGlissants(n) {
  const sortie = [];
  for (let i = n - 1; i >= 0; i--) sortie.push(jourDe(new Date(Date.now() - i * 864e5).toISOString()));
  return sortie;
}

/* ---------- graphe en aire ---------- */

/**
 * Petit graphe en aire, une seule serie. Toujours construit a partir de
 * vraies valeurs passees en argument — jamais de donnee inventee : une
 * carte sans historique reel n'a pas de graphe, plutot qu'un faux.
 */
export function grapheAires(valeurs, { hauteur = 64, couleur = 'var(--encre-douce)', voile = 'var(--surface-haute)' } = {}) {
  const L = 100, H = hauteur, marge = 2;
  const n = valeurs.length;
  const max = Math.max(1, ...valeurs);
  const x = (i) => (n <= 1 ? L / 2 : marge + (i / (n - 1)) * (L - marge * 2));
  const y = (v) => H - marge - (v / max) * (H - marge * 2);
  const ligne = valeurs.map((v, i) => `${x(i).toFixed(2)},${y(v).toFixed(2)}`).join(' ');
  const aire = `${marge},${H - marge} ${ligne} ${L - marge},${H - marge}`;

  return h('svg', {
    viewBox: `0 0 ${L} ${H}`, preserveAspectRatio: 'none',
    style: { width: '100%', height: hauteur + 'px', display: 'block' },
    html: `
      <polyline points="${aire}" fill="${voile}" stroke="none" />
      <polyline points="${ligne}" fill="none" stroke="${couleur}" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round" vector-effect="non-scaling-stroke" />
    `,
  });
}

/* ---------- cartes de synthese ---------- */

// Une seule banque d'icones pour toutes les vues : cinq fichiers construisaient
// chacun leurs propres cartes .mesure avec un balisage legerement different.
// Centraliser evite que l'un d'eux derive visuellement des autres au fil du
// temps.
const ICONES_MESURE = {
  demandes: '<path d="M4 5h16v12H8l-4 4V5Z"/>',
  crayon:   '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
  clients:  '<circle cx="9" cy="7" r="3.2"/><path d="M2.5 20c0-3.4 2.9-6 6.5-6s6.5 2.6 6.5 6"/><circle cx="17" cy="6.6" r="2.4"/><path d="M15.3 14.3c2.4.6 4.2 2.8 4.2 5.7"/>',
  revenu:   '<path d="M17.5 7a6.5 6.5 0 1 0 0 10"/><path d="M4 10h9M4 14h7.5"/>',
  reussite: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
  visites:  '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  cible:    '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4.2"/><circle cx="12" cy="12" r=".6" fill="currentColor" stroke="none"/>',
  campagne: '<path d="M3 10v4h4l6 4V6L7 10H3Z"/><path d="M17 9a4 4 0 0 1 0 6"/>',
  horloge:  '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
};

/**
 * Carte de synthese en tete de page : badge rond (porte le ton), grand
 * chiffre, libelle, note courte. `icone` est une cle de ICONES_MESURE ;
 * `ton` est '' | 'action' | 'bien' | 'veille'.
 */
export function mesure(icone, etiq, val, ton, sous) {
  return h('div.mesure', { 'data-ton': ton || null },
    h('div.mesure-icone', h('svg', {
      viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor',
      'stroke-width': '1.8', 'stroke-linecap': 'round', 'stroke-linejoin': 'round',
      html: ICONES_MESURE[icone] || '',
    })),
    h('p.val', typeof val === 'number' ? nombre(val) : val),
    h('p.etiq', etiq),
    sous ? h('p.sous', sous) : null,
  );
}

/* ---------- messages ---------- */

let minuterie;
export function souffler(texte, ton = 'bien') {
  let el = $('#souffle');
  if (!el) {
    el = h('div', { id: 'souffle', style: {
      position: 'fixed', bottom: '20px', left: '50%', transform: 'translateX(-50%) translateY(10px) scale(.97)',
      zIndex: '90', padding: '10px 18px', borderRadius: '100px',
      boxShadow: 'var(--ombre-haute)', fontSize: '.875rem', fontWeight: '600',
      transition: 'opacity .22s var(--detente), transform .22s var(--detente)', pointerEvents: 'none',
      opacity: '0',
    }});
    document.body.append(el);
  }
  const fonds = { bien: 'var(--vert)', alerte: 'var(--alerte)', veille: 'var(--ambre)' };
  el.style.background = fonds[ton] || 'var(--encre)';
  el.style.color = '#fff';
  el.textContent = texte;
  // Repartir de "cache" a chaque appel, meme si un souffle precedent est
  // encore visible : sinon un deuxieme message qui arrive vite ne rejoue
  // pas l'entree, il change juste de texte sans a-coup visible.
  el.style.opacity = '0';
  el.style.transform = 'translateX(-50%) translateY(10px) scale(.97)';
  void el.offsetWidth;
  el.style.opacity = '1';
  el.style.transform = 'translateX(-50%) translateY(0) scale(1)';
  clearTimeout(minuterie);
  minuterie = setTimeout(() => {
    el.style.opacity = '0';
    el.style.transform = 'translateX(-50%) translateY(8px) scale(.97)';
  }, 2600);
}

/* Enregistrement differe : on ne part pas en base a chaque touche.
   700 ms apres la derniere frappe suffit — c'est le temps d'une pause
   naturelle, et ca divise par vingt le nombre de requetes. */
export function differer(fn, delai = 700) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), delai);
  };
}

/* Confirmation pour les gestes qu'on ne peut pas defaire. Volontairement
   un `confirm` natif : c'est laid, et c'est exactement l'effet voulu — on
   veut que la main s'arrete. */
export function certain(question) {
  return window.confirm(question);
}
