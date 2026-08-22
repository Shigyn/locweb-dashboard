// ===================================================================
//  Accueil — la liste des clients.
//
//  C'est la page qu'on ouvre le matin. Elle doit repondre a une seule
//  question en un coup d'oeil : QUI a besoin de moi aujourd'hui ?
//
//  D'ou le classement : les clients qui demandent une action remontent
//  en tete, ceux qui vont bien descendent. Trier par ordre alphabetique
//  serait plus previsible, mais obligerait a lire toute la liste chaque
//  matin pour trouver les trois lignes qui comptent.
// ===================================================================

import { h, vider, nombre, euros, depuis, pastilleEtat, ETATS_CLIENT, differer, mesure, grapheAires, joursGlissants } from './outils.js';
import * as D from './donnees.js';
import { charger, tete, oublier } from './app.js';
import { METIERS } from './metiers.js';

export async function rendre(page) {
  const [clients, demandes, brouillons, visites] = await Promise.all([
    charger('clients',    () => D.listerClients()),
    charger('demandes',   () => D.listerDemandes({})),
    charger('brouillons', () => D.brouillonsEnAttente()),
    charger('visites30',  () => D.listerVisites({ jours: 30 })),
  ]);

  // Un seul passage sur chaque liste plutot qu'un filtre par client :
  // avec cinquante clients et deux mille visites, la difference se voit.
  const parClient = new Map(clients.map((c) => [c.id, {
    client: c, nouvelles: 0, demandes30: 0, brouillons: brouillons.get(c.id) || 0,
    visites30: 0, derniere: null,
  }]));

  const limite = Date.now() - 30 * 864e5;
  for (const d of demandes) {
    const l = parClient.get(d.client_id);
    if (!l) continue;
    if ((d.statut || 'nouvelle') === 'nouvelle') l.nouvelles++;
    if (new Date(d.date_creation) >= limite) l.demandes30++;
    if (!l.derniere || d.date_creation > l.derniere) l.derniere = d.date_creation;
  }
  for (const v of visites) {
    const l = parClient.get(v.client_id);
    if (l) l.visites30++;
  }

  const lignes = [...parClient.values()];
  for (const l of lignes) l.signal = signalDe(l);

  tete(
    h('h1', 'Clients'),
    h('a.bt.bt-plein', { href: '#/demandes' }, 'Voir les demandes'),
    h('button.bt.bt-nu', { onclick: () => { oublier(); location.reload(); }, title: 'Recharger les donnees' }, 'Actualiser'),
  );

  /* ---------- bandeau de synthese ---------- */

  const actifs = clients.filter((c) => c.statut === 'actif');
  const mrr = actifs.reduce((s, c) => s + Number(c.tarif_mensuel || 0), 0);
  const totalNouvelles = lignes.reduce((s, l) => s + l.nouvelles, 0);
  const totalBrouillons = lignes.reduce((s, l) => s + l.brouillons, 0);

  page.append(
    h('div.synthese',
      mesure('horloge', 'Demandes a traiter', totalNouvelles, totalNouvelles ? 'action' : 'bien',
        totalNouvelles ? 'en attente de reponse' : 'tout est traite'),
      mesure('crayon', 'Modifications en attente', totalBrouillons, totalBrouillons ? 'veille' : 'bien',
        totalBrouillons ? 'pas encore publiees' : 'rien a publier'),
      mesure('clients', 'Clients actifs', actifs.length, 'bien',
        `${clients.length - actifs.length} autre${clients.length - actifs.length > 1 ? 's' : ''} en cours`),
      mesure('revenu', 'Revenu mensuel', euros(mrr), '', 'abonnements actifs'),
    ),
  );

  /* ---------- tendance 14 jours, tous clients ---------- */

  const parJour14 = joursGlissants(14);
  const visitesParJour = new Map(parJour14.map((j) => [j, 0]));
  for (const v of visites) {
    const j = new Date(v.horodatage).toISOString().slice(0, 10);
    if (visitesParJour.has(j)) visitesParJour.set(j, visitesParJour.get(j) + 1);
  }
  const serieVisites = parJour14.map((j) => visitesParJour.get(j));
  const totalVisites14 = serieVisites.reduce((s, v) => s + v, 0);

  page.append(h('div.carte',
    h('div.carte-tete',
      h('h2', 'Visites — 14 derniers jours'),
      h('span.droite', h('a.bt.bt-nu.bt-mini', { href: '#/performances' }, 'Voir le detail'))),
    h('div.carte-corps',
      totalVisites14
        ? h('div', { style: { display: 'flex', alignItems: 'center', gap: '18px' } },
            h('div', { style: { flex: '1' } }, grapheAires(serieVisites, { hauteur: 56 })),
            h('div', { style: { flex: 'none', textAlign: 'right' } },
              h('p.val', { style: { fontFamily: 'var(--mono)', fontSize: '1.5rem', fontWeight: '650' } }, nombre(totalVisites14)),
              h('p', { style: { fontSize: '.78rem', color: 'var(--sourdine)' } }, 'visites cumulees')))
        : h('p', { style: { color: 'var(--sourdine)', fontSize: '.86rem' } },
            "Pas encore de visites enregistrees — le journal se remplit des que les sites clients sont branches dessus."))));

  /* ---------- filtre ---------- */

  const liste = h('div.clients');
  const recherche = h('input', {
    type: 'text', placeholder: 'Filtrer par nom, ville ou metier...',
    style: { maxWidth: '320px' },
    oninput: differer((e) => dessiner(e.target.value), 180),
  });

  page.append(
    h('div', { style: { display: 'flex', gap: '10px', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap' } },
      recherche,
      h('span', { style: { color: 'var(--sourdine)', fontSize: '.82rem' } },
        `${clients.length} client${clients.length > 1 ? 's' : ''}`),
    ),
    liste,
  );

  function dessiner(filtre = '') {
    const f = filtre.toLowerCase().trim();
    const vues = lignes
      .filter((l) => !f || [l.client.nom_site, l.client.ville, METIERS[l.client.metier]?.libelle, l.client.domaine]
        .some((x) => (x || '').toLowerCase().includes(f)))
      .sort(comparer);

    vider(liste);
    if (!vues.length) {
      liste.append(h('div.carte', h('p.vide',
        h('strong', clients.length ? 'Aucun client ne correspond' : 'Aucun client'),
        clients.length ? 'Essayez un autre terme.' : 'Les clients apparaitront ici une fois crees dans Supabase.')));
      return;
    }
    // Decalage plafonne : au-dela d'une vingtaine de lignes, tout le
    // monde partage le meme delai plutot que d'etaler l'apparition sur
    // plusieurs secondes pour une longue liste.
    vues.forEach((l, i) => liste.append(carteClient(l, Math.min(i, 20) * 22)));
  }

  dessiner();
}

/* ------------------------------------------------------------------
   Le signal : ce que la ligne reclame.
     action — quelque chose attend une intervention aujourd'hui
     veille — rien d'urgent mais quelque chose se prepare
     calme  — le client tourne, on peut passer son chemin
   ------------------------------------------------------------------ */
function signalDe(l) {
  if (l.client.statut === 'suspendu') return 'action';
  if (l.nouvelles > 0) return 'action';
  if (l.brouillons > 0) return 'veille';
  if (l.client.statut === 'en_construction') return 'veille';
  if (l.client.statut === 'actif') return 'calme';
  return '';
}

const RANG = { action: 0, veille: 1, calme: 2, '': 3 };

function comparer(a, b) {
  const r = RANG[a.signal] - RANG[b.signal];
  if (r) return r;
  if (a.nouvelles !== b.nouvelles) return b.nouvelles - a.nouvelles;
  return (a.client.nom_site || '').localeCompare(b.client.nom_site || '');
}

function carteClient(l, delaiMs = 0) {
  const c = l.client;
  const meta = [METIERS[c.metier]?.libelle, c.ville].filter(Boolean).join(' · ') || c.domaine || 'Metier non renseigne';

  return h('a.client', { href: `#/client/${c.id}`, 'data-signal': l.signal, style: { '--d': delaiMs } },
    h('span.liset'),

    h('span.client-id',
      h('span.nom', c.nom_site || 'Sans nom', pastilleEtat(c.statut, ETATS_CLIENT)),
      h('span.meta', meta),
    ),

    colonne('Demandes', l.nouvelles || l.demandes30, l.nouvelles > 0,
      l.nouvelles ? `${l.nouvelles} nouvelle${l.nouvelles > 1 ? 's' : ''}` : '30 derniers jours'),

    colonne('Visites', l.visites30, false, '30 derniers jours'),

    colonne('A publier', l.brouillons, false,
      l.derniere ? `contact ${depuis(l.derniere)}` : 'aucun contact'),

    h('span', { style: { color: 'var(--sourdine)' } },
      h('svg', { viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor',
        'stroke-width': '1.8', 'stroke-linecap': 'round', 'stroke-linejoin': 'round',
        style: { width: '17px', height: '17px', display: 'block' },
        html: '<path d="m9 6 6 6-6 6"/>' })),
  );
}

function colonne(etiq, valeur, chaud, sous) {
  return h('span.colonne',
    h('span.etiq', etiq),
    h('span.nb', { class: `nb${valeur ? (chaud ? ' chaud' : '') : ' rien'}` }, nombre(valeur)),
    h('span', { style: { display: 'block', fontSize: '.72rem', color: 'var(--sourdine)' } }, sous),
  );
}
