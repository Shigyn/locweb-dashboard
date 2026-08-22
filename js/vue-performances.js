// ===================================================================
//  Performances — tous clients confondus.
//
//  Reponds a une question d'exploitant, pas d'analyste : est-ce que le
//  trafic se transforme en demandes, et pour quels clients ce n'est
//  PAS le cas (site qui recoit des visites mais aucun contact — signe
//  d'un probleme de formulaire ou d'un mauvais positionnement, pas
//  d'un manque de trafic).
// ===================================================================

import { h, vider, nombre, mesure, jourDe, joursGlissants } from './outils.js';
import * as D from './donnees.js';
import { charger, tete, oublier } from './app.js';

export async function rendre(page) {
  const [clients, visites, demandes] = await Promise.all([
    charger('clients',   () => D.listerClients()),
    charger('visites30', () => D.listerVisites({ jours: 30 })),
    charger('demandes',  () => D.listerDemandes({})),
  ]);

  tete(
    h('h1', 'Performances'),
    h('button.bt.bt-nu', { onclick: () => { oublier(); location.reload(); } }, 'Actualiser'),
  );

  const limite = Date.now() - 30 * 864e5;
  const demandes30 = demandes.filter((d) => new Date(d.date_creation) >= limite);
  const taux = visites.length ? (demandes30.length / visites.length * 100) : 0;

  page.append(h('div.synthese',
    mesure('visites', 'Visites (30 j)', visites.length, '', 'tous clients confondus'),
    mesure('demandes', 'Demandes (30 j)', demandes30.length, '', 'formulaires soumis'),
    mesure('cible', 'Taux de conversion', visites.length ? `${taux.toFixed(1)} %` : '—',
      taux >= 2 ? 'bien' : (visites.length ? 'veille' : ''), 'visites -> demandes'),
  ));

  /* ---------- courbe des visites, 30 jours ---------- */

  const parJour = joursGlissants(30);
  const visitesParJour = new Map(parJour.map((j) => [j, 0]));
  const demandesParJour = new Map(parJour.map((j) => [j, 0]));
  for (const v of visites) { const j = jourDe(v.horodatage); if (visitesParJour.has(j)) visitesParJour.set(j, visitesParJour.get(j) + 1); }
  for (const d of demandes30) { const j = jourDe(d.date_creation); if (demandesParJour.has(j)) demandesParJour.set(j, demandesParJour.get(j) + 1); }

  const serieVisites = parJour.map((j) => visitesParJour.get(j));
  const serieDemandes = parJour.map((j) => demandesParJour.get(j));

  page.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Visites et demandes — 30 derniers jours')),
    h('div.carte-corps',
      visites.length
        ? graphe(serieVisites, serieDemandes)
        : h('p.vide',
            h('strong', 'Pas encore de donnees'),
            "Le journal de visites se remplit des que les sites clients sont branches dessus."),
      h('div.legende',
        h('span', h('i', { style: { background: 'var(--accent)' } }), 'Visites'),
        h('span', h('i', { style: { background: 'var(--ambre)' } }), 'Demandes')),
    )));

  /* ---------- provenance du trafic ---------- */

  if (visites.length) {
    const parSource = new Map();
    for (const v of visites) {
      const s = classerSource(v.referent);
      parSource.set(s, (parSource.get(s) || 0) + 1);
    }
    const lignesSource = [...parSource.entries()].sort((a, b) => b[1] - a[1]);
    const max = lignesSource[0][1];

    page.append(h('div.carte',
      h('div.carte-tete', h('h2', 'Provenance du trafic — 30 derniers jours')),
      h('div.carte-corps', h('div', { style: { display: 'grid', gap: '10px' } },
        ...lignesSource.map(([source, n]) => h('div', {
          style: { display: 'grid', gridTemplateColumns: '110px 1fr 60px', gap: '12px', alignItems: 'center' },
        },
          h('span', { style: { fontSize: '.86rem', fontWeight: '600' } }, source),
          h('div', { style: { background: 'var(--surface-haute)', borderRadius: '100px', height: '8px', overflow: 'hidden' } },
            h('div', { style: { background: 'var(--encre-douce)', height: '100%', width: `${(n / max * 100).toFixed(0)}%`, borderRadius: '100px' } })),
          h('span.mono', { style: { fontSize: '.82rem', textAlign: 'right', color: 'var(--sourdine)' } }, nombre(n))),
        )))));
  }

  /* ---------- classement par client ---------- */

  const parClient = new Map(clients.map((c) => [c.id, { client: c, visites: 0, demandes: 0 }]));
  for (const v of visites) { const l = parClient.get(v.client_id); if (l) l.visites++; }
  for (const d of demandes30) { const l = parClient.get(d.client_id); if (l) l.demandes++; }

  const lignes = [...parClient.values()]
    .filter((l) => l.visites > 0 || l.demandes > 0)
    .sort((a, b) => b.visites - a.visites);

  const corps = h('tbody');
  for (const l of lignes) {
    const t = l.visites ? (l.demandes / l.visites * 100) : null;
    const silencieux = l.visites >= 20 && l.demandes === 0;
    corps.append(h('tr',
      h('td', h('a', { href: `#/client/${l.client.id}`, style: { fontWeight: '600', textDecoration: 'none' } },
        l.client.nom_site || 'Sans nom')),
      h('td.nb.mono', nombre(l.visites)),
      h('td.nb.mono', nombre(l.demandes)),
      h('td.nb.mono', t === null ? '—' : `${t.toFixed(1)} %`),
      h('td', silencieux ? h('span.etat', { 'data-ton': 'veille' }, 'trafic sans contact') : ''),
    ));
  }

  page.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Par client — 30 derniers jours')),
    h('div.carte-corps.serre',
      lignes.length
        ? h('div.tableau-cadre', h('table',
            h('thead', h('tr', h('th', 'Client'), h('th.nb', 'Visites'), h('th.nb', 'Demandes'), h('th.nb', 'Conversion'), h('th', ''))),
            corps))
        : h('p.vide', h('strong', 'Aucune donnee'), 'Aucun client n a recu de visite sur la periode.'))));
}

/* Graphe en aires + points, dessine en SVG. Aucune bibliotheque : trente
   points ne le justifient pas, et un SVG construit ici reste lisible en
   PDF ou en impression le jour ou quelqu'un veut imprimer ce tableau. */
function graphe(visites, demandesSerie) {
  const L = 760, H = 172, marge = 8;
  const maxV = Math.max(1, ...visites);
  const n = visites.length;
  const x = (i) => marge + (i / (n - 1)) * (L - marge * 2);
  const yV = (v) => H - marge - (v / maxV) * (H - marge * 2);

  const ligneVisites = visites.map((v, i) => `${x(i).toFixed(1)},${yV(v).toFixed(1)}`).join(' ');
  const aire = `${marge},${H - marge} ${ligneVisites} ${L - marge},${H - marge}`;

  const maxD = Math.max(1, ...demandesSerie);
  const points = demandesSerie.map((d, i) => d > 0
    ? `<circle cx="${x(i).toFixed(1)}" cy="${(H - marge - (d / maxD) * (H - marge * 2) * 0.9).toFixed(1)}" r="3" fill="var(--ambre)" />`
    : '').join('');

  const svg = h('svg.graphe', {
    viewBox: `0 0 ${L} ${H}`, preserveAspectRatio: 'none',
    html: `
      <polyline points="${aire}" fill="var(--accent-voile)" stroke="none" />
      <polyline points="${ligneVisites}" fill="none" stroke="var(--accent)" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" />
      ${points}
      <line x1="${marge}" y1="${H - marge}" x2="${L - marge}" y2="${H - marge}" stroke="var(--trait)" stroke-width="1" />
    `,
  });
  return svg;
}

/* Classement du referent brut en source lisible. Beaucoup de visiteurs
   n'ont aucun referent (favori, application, HTTPS -> HTTPS direct) : ce
   n'est pas une lacune de la mesure, c'est le comportement normal du web,
   d'ou le libelle "Direct" plutot qu'une case vide. */
function classerSource(referent) {
  if (!referent) return 'Direct';
  const r = referent.toLowerCase();
  if (r.includes('google.')) return 'Google';
  if (r.includes('facebook.com') || r.includes('fb.com')) return 'Facebook';
  if (r.includes('instagram.com')) return 'Instagram';
  if (r.includes('bing.com')) return 'Bing';
  return 'Autres';
}
