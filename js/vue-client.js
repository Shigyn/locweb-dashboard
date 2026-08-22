// ===================================================================
//  Fiche client.
//
//  Cinq onglets, un seul principe : ce qu'on modifie ici ne part PAS en
//  ligne tant qu'on n'a pas publie. La barre du bas compte ce qui
//  attend, et c'est le seul endroit d'ou le site public peut changer.
// ===================================================================

import {
  h, vider, esc, nombre, euros, depuis, dateLongue, differer, souffler, certain,
  pastilleEtat, ETATS_CLIENT, ETATS_DEMANDE, ETATS_CAMPAGNE, mesure,
} from './outils.js';
import * as D from './donnees.js';
import { charger, oublier, tete, rafraichirPastilles } from './app.js';
import { MANIFEST, GROUP_ORDER } from './manifest.js';
import { LISTE_METIERS, METIERS, suggerer, negatifs, accroches } from './metiers.js';

const ONGLETS = [
  { cle: 'contenu',   libelle: 'Contenu' },
  { cle: 'demandes',  libelle: 'Demandes' },
  { cle: 'campagnes', libelle: 'Campagnes' },
  { cle: 'profil',    libelle: 'Profil' },
  { cle: 'reglages',  libelle: 'Reglages' },
];

export async function rendre(page, [clientId, ongletDemande]) {
  if (!clientId) { location.hash = '#/clients'; return; }

  const [client, contenu, demandes, campagnes, profil, visites] = await Promise.all([
    D.lireClient(clientId),
    D.lireContenu(clientId),
    D.listerDemandes({ clientId }),
    D.listerCampagnes(clientId),
    D.lireProfil(clientId),
    D.listerVisites({ clientId, jours: 30 }),
  ]);

  const ctx = { client, contenu, demandes, campagnes, profil, visites, page };

  tete(
    h('div', { style: { display: 'flex', flexDirection: 'column' } },
      h('div.fil', h('a', { href: '#/clients' }, 'Clients'), '/'),
      h('h1', { style: { display: 'flex', alignItems: 'center', gap: '10px' } },
        client.nom_site || 'Sans nom',
        pastilleEtat(client.statut, ETATS_CLIENT)),
    ),
    client.domaine
      ? h('a.bt.bt-plein', { href: adresse(client.domaine), target: '_blank', rel: 'noopener noreferrer' },
          'Ouvrir le site',
          h('svg', { viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '1.8',
            'stroke-linecap': 'round', style: { width: '14px', height: '14px' },
            html: '<path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M18 13v6a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h6"/>' }))
      : null,
  );

  /* ---------- onglets ---------- */

  const nouvelles = demandes.filter((d) => (d.statut || 'nouvelle') === 'nouvelle').length;
  const enAttente = contenu.filter((l) => l.valeur_brouillon !== null).length;
  const compteurs = { contenu: enAttente, demandes: nouvelles, campagnes: campagnes.filter((c) => c.statut === 'demandee').length };

  const corps = h('div.onglet-corps');
  const barreOnglets = h('div.onglets', { role: 'tablist' });

  const boutons = ONGLETS.map((o) => {
    const n = compteurs[o.cle] || 0;
    const b = h('button', {
      role: 'tab', type: 'button', 'aria-selected': 'false',
      onclick: () => choisir(o.cle),
    }, o.libelle, n ? h('span.compte', nombre(n)) : null);
    barreOnglets.append(b);
    return { ...o, b };
  });

  function choisir(cle) {
    boutons.forEach((o) => o.b.setAttribute('aria-selected', String(o.cle === cle)));
    history.replaceState(null, '', `#/client/${clientId}/${cle}`);
    vider(corps);
    ({ contenu: ongletContenu, demandes: ongletDemandes, campagnes: ongletCampagnes,
       profil: ongletProfil, reglages: ongletReglages })[cle](corps, ctx);
    // Meme noeud DOM reutilise a chaque onglet : sans ce coup de force,
    // la CSS animation d'entree ne rejouerait qu'une fois.
    corps.classList.remove('onglet-corps');
    void corps.offsetWidth;
    corps.classList.add('onglet-corps');
  }

  page.append(barreOnglets, corps);
  choisir(ONGLETS.some((o) => o.cle === ongletDemande) ? ongletDemande : 'contenu');
}

function adresse(domaine) {
  return /^https?:\/\//.test(domaine) ? domaine : `https://${domaine}`;
}

/* ==================================================================
   Onglet CONTENU
   ================================================================== */

function ongletContenu(hote, ctx) {
  const { contenu, client } = ctx;

  if (!contenu.length) {
    hote.append(h('div.carte', h('p.vide',
      h('strong', 'Aucune zone editable'),
      "Ce site n'a pas encore de contenu branche sur la base.")));
    return;
  }

  // Un compteur vivant : il suit les modifications au fil de la frappe
  // sans qu'on ait a relire la base.
  const attente = new Map(contenu.filter((l) => l.valeur_brouillon !== null).map((l) => [l.id, true]));

  const barre = h('div.publication');
  const compteur = h('span.compte-modifs');
  const btPublier = h('button.bt.bt-vif', { onclick: publier }, 'Publier les modifications');
  const btAnnuler = h('button.bt.bt-nu', { onclick: annuler }, 'Tout annuler');
  barre.append(compteur, h('span.droite', btAnnuler, btPublier));

  function majBarre() {
    const n = attente.size;
    vider(compteur);
    compteur.append(n
      ? h('span', h('b', nombre(n)), ` modification${n > 1 ? 's' : ''} en attente — le site public n'a pas encore change.`)
      : h('span', { style: { color: 'var(--sourdine)' } }, 'Tout est publie. Le site en ligne est a jour.'));
    btPublier.disabled = n === 0;
    btAnnuler.disabled = n === 0;
  }

  async function publier() {
    if (!certain(`Publier ${attente.size} modification(s) ? Le site sera mis a jour immediatement.`)) return;
    btPublier.disabled = true;
    btPublier.textContent = 'Publication...';
    try {
      const n = await D.publier(client.id);
      attente.clear();
      contenu.forEach((l) => {
        if (l.valeur_brouillon !== null) { l.valeur = l.valeur_brouillon; l.valeur_brouillon = null; }
      });
      hote.querySelectorAll('.zone-champ.modifie').forEach((el) => {
        el.classList.remove('modifie');
        el.querySelector('.drapeau')?.remove();
      });
      oublier('brouillons');
      souffler(`${n} modification${n > 1 ? 's' : ''} en ligne.`, 'bien');
    } catch (e) {
      souffler('Publication impossible : ' + (e.message || e), 'alerte');
    }
    btPublier.textContent = 'Publier les modifications';
    majBarre();
  }

  async function annuler() {
    if (!certain('Annuler toutes les modifications non publiees ? Elles seront perdues.')) return;
    try {
      await D.annulerBrouillons(client.id);
      contenu.forEach((l) => { l.valeur_brouillon = null; });
      attente.clear();
      oublier('brouillons');
      vider(hote);
      ongletContenu(hote, ctx);
      souffler('Modifications annulees.', 'veille');
    } catch (e) {
      souffler('Annulation impossible : ' + (e.message || e), 'alerte');
    }
  }

  /* --- regroupement par section, dans l'ordre du manifeste --- */

  const groupes = new Map();
  for (const ligne of contenu) {
    const g = MANIFEST[ligne.cle_bloc]?.groupe || 'Autres';
    if (!groupes.has(g)) groupes.set(g, []);
    groupes.get(g).push(ligne);
  }

  const ordre = [...GROUP_ORDER.filter((g) => groupes.has(g)),
                 ...[...groupes.keys()].filter((g) => !GROUP_ORDER.includes(g))];

  for (const nomGroupe of ordre) {
    const lignes = groupes.get(nomGroupe);
    const zones = h('div.zones');
    lignes.forEach((l) => zones.append(champ(l)));
    hote.append(h('div.carte',
      h('div.carte-tete',
        h('h2', nomGroupe),
        h('span.droite', h('span', { style: { color: 'var(--sourdine)', fontSize: '.8rem' } },
          `${lignes.length} zone${lignes.length > 1 ? 's' : ''}`))),
      h('div.carte-corps.serre', zones)));
  }

  hote.append(barre);
  majBarre();

  function champ(ligne) {
    const info = MANIFEST[ligne.cle_bloc];
    const enLigne = ligne.valeur ?? '';
    const courant = ligne.valeur_brouillon ?? enLigne;
    const modifie = ligne.valeur_brouillon !== null;

    const drapeau = h('span.drapeau',
      h('svg', { viewBox: '0 0 24 24', fill: 'currentColor', style: { width: '11px', height: '11px' },
        html: '<circle cx="12" cy="12" r="6"/>' }),
      'non publie');

    // Un champ long merite une zone de texte ; un titre merite une
    // ligne. Le seuil est empirique et sans consequence : se tromper
    // donne juste un champ un peu grand ou un peu petit.
    const longue = courant.length > 90 || /\n/.test(courant) || /(texte|desc|message|paragraphe)/.test(ligne.cle_bloc);
    const saisie = h(longue ? 'textarea' : 'input', {
      type: longue ? null : 'text',
      value: courant,
      rows: longue ? Math.min(7, Math.max(3, Math.ceil(courant.length / 74))) : null,
    });

    const bloc = h('div.zone-champ',
      h('div.libelle',
        h('div.nom', info?.label || joli(ligne.cle_bloc)),
        h('div.cle', ligne.cle_bloc),
        modifie ? drapeau : null),
      saisie);

    if (modifie) bloc.classList.add('modifie');

    const enregistrer = differer(async (v) => {
      try {
        const revenuAuPoint = await D.ecrireBrouillon(ligne.id, v, enLigne);
        ligne.valeur_brouillon = revenuAuPoint ? null : v;
        if (revenuAuPoint) {
          attente.delete(ligne.id);
          bloc.classList.remove('modifie');
          drapeau.remove();
        } else {
          attente.set(ligne.id, true);
          bloc.classList.add('modifie');
          if (!drapeau.isConnected) bloc.querySelector('.libelle').append(drapeau);
        }
        majBarre();
      } catch (e) {
        souffler('Enregistrement impossible : ' + (e.message || e), 'alerte');
      }
    });

    saisie.addEventListener('input', () => enregistrer(saisie.value));
    return bloc;
  }
}

function joli(cle) {
  const s = String(cle).replace(/_/g, ' ');
  return s.charAt(0).toUpperCase() + s.slice(1);
}

/* ==================================================================
   Onglet DEMANDES
   ================================================================== */

function ongletDemandes(hote, ctx) {
  const { demandes } = ctx;

  if (!demandes.length) {
    hote.append(h('div.carte', h('p.vide',
      h('strong', 'Aucune demande'),
      "Les formulaires du site arriveront ici des la premiere soumission.")));
    return;
  }

  const gagnees = demandes.filter((d) => d.statut === 'gagnee').length;
  const traitees = demandes.filter((d) => d.statut && d.statut !== 'nouvelle').length;

  hote.append(h('div.synthese',
    mesure('demandes', 'Total recu', demandes.length, '', 'depuis la mise en ligne'),
    mesure('horloge', 'A traiter', demandes.length - traitees, 'action', 'sans reponse'),
    mesure('reussite', 'Gagnees', gagnees, 'bien',
      traitees ? `${Math.round(gagnees / traitees * 100)} % des demandes traitees` : '—'),
  ));

  hote.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Toutes les demandes')),
    h('div.carte-corps.serre', tableauDemandes(demandes)),
  ));
}

export function tableauDemandes(demandes, montrerClient = null) {
  const corps = h('tbody');

  for (const d of demandes) {
    const select = h('select', {
      style: { minWidth: '140px' },
      onchange: async (e) => {
        const avant = d.statut || 'nouvelle';
        try {
          await D.majDemande(d.id, { statut: e.target.value });
          d.statut = e.target.value;
          oublier('demandes');
          rafraichirPastilles();
          souffler('Statut enregistre.', 'bien');
        } catch (err) {
          e.target.value = avant;
          souffler('Enregistrement impossible.', 'alerte');
        }
      },
    }, ...Object.entries(ETATS_DEMANDE).map(([cle, e]) =>
      h('option', { value: cle, selected: (d.statut || 'nouvelle') === cle }, e.libelle)));

    const detail = h('tr', { hidden: true },
      h('td', { colspan: montrerClient ? 6 : 5, style: { background: 'var(--surface-creux)' } },
        h('div', { style: { display: 'grid', gap: '8px', maxWidth: '760px' } },
          d.message ? h('p', { style: { whiteSpace: 'pre-wrap' } }, d.message) : h('p', { style: { color: 'var(--sourdine)' } }, 'Aucun message.'),
          h('p', { style: { fontSize: '.8rem', color: 'var(--sourdine)' } },
            [d.email, d.ville, d.besoin].filter(Boolean).join(' · ') || '—',
            ' — recue le ', dateLongue(d.date_creation)),
        )));

    const ligne = h('tr', { style: { cursor: 'pointer' }, onclick: (e) => {
      if (e.target.closest('select, a, button')) return;
      detail.hidden = !detail.hidden;
    } },
      montrerClient ? h('td', montrerClient(d.client_id)) : null,
      h('td',
        h('div', { style: { fontWeight: '600' } }, d.nom || 'Sans nom'),
        h('div', { style: { fontSize: '.8rem', color: 'var(--sourdine)' } }, d.besoin || d.ville || '—')),
      h('td', d.telephone
        ? h('a.mono', { href: `tel:${String(d.telephone).replace(/\s/g, '')}`, style: { textDecoration: 'none', fontSize: '.85rem' } }, d.telephone)
        : h('span', { style: { color: 'var(--sourdine)' } }, '—')),
      h('td', { style: { color: 'var(--sourdine)', fontSize: '.82rem', whiteSpace: 'nowrap' } }, depuis(d.date_creation)),
      h('td', select),
    );

    corps.append(ligne, detail);
  }

  return h('div.tableau-cadre', h('table',
    h('thead', h('tr',
      montrerClient ? h('th', 'Client') : null,
      h('th', 'Demandeur'), h('th', 'Telephone'), h('th', 'Recue'), h('th', 'Suivi'))),
    corps));
}

/* ==================================================================
   Onglet CAMPAGNES
   ================================================================== */

function ongletCampagnes(hote, ctx) {
  const { client, campagnes } = ctx;
  const metier = client.metier || 'autre';

  /* --- proposition de mots-cles --- */

  const propositions = suggerer({
    metier,
    ville: client.ville,
    nomEntreprise: client.nom_site,
    codePostal: client.code_postal,
  }).slice(0, 40);

  const choisis = new Set(propositions.filter((p) => p.score >= 100).map((p) => p.texte));
  const grille = h('div.grille-mots');

  const INTENTIONS = { urgence: 'Urgence', projet: 'Projet', info: 'Info', marque: 'Marque' };

  propositions.forEach((p) => {
    const case_ = h('input', {
      type: 'checkbox', checked: choisis.has(p.texte),
      onchange: (e) => { e.target.checked ? choisis.add(p.texte) : choisis.delete(p.texte); majResume(); },
    });
    grille.append(h('label.mot-cle', { 'data-intention': p.intention },
      case_, h('span.texte', p.texte), h('span.intention', INTENTIONS[p.intention])));
  });

  const resume = h('p', { style: { color: 'var(--sourdine)', fontSize: '.83rem' } });
  function majResume() { resume.textContent = `${choisis.size} mot-cle(s) retenu(s)`; }
  majResume();

  hote.append(h('div.carte',
    h('div.carte-tete',
      h('h2', 'Mots-cles proposes'),
      h('span.droite', resume,
        h('button.bt.bt-plein.bt-mini', { onclick: () => copier([...choisis].join('\n'), 'Mots-cles copies.') }, 'Copier'))),
    h('div.carte-corps',
      h('p', { style: { color: 'var(--sourdine)', marginBottom: '14px', fontSize: '.86rem' } },
        client.ville
          ? `Croisement de « ${METIERS[metier]?.libelle || metier} » avec « ${client.ville} ». Les urgences sont cochees par defaut : ce sont elles qui font sonner le telephone.`
          : "Renseignez la ville dans l'onglet Reglages pour que les mots-cles soient declines localement."),
      grille)));

  /* --- negatifs et accroches --- */

  const listeNeg = negatifs(metier);
  hote.append(h('div.carte',
    h('div.carte-tete',
      h('h2', 'Mots-cles a exclure'),
      h('span.droite',
        h('span', { style: { color: 'var(--sourdine)', fontSize: '.83rem' } }, `${listeNeg.length} termes`),
        h('button.bt.bt-plein.bt-mini', { onclick: () => copier(listeNeg.join('\n'), 'Exclusions copiees.') }, 'Copier'))),
    h('div.carte-corps',
      h('p', { style: { color: 'var(--sourdine)', marginBottom: '12px', fontSize: '.86rem' } },
        "A coller en negatifs dans Google Ads. C'est la premiere economie d'une campagne : personne qui cherche un salaire ou une formation ne deviendra client."),
      h('p', { style: { fontFamily: 'var(--mono)', fontSize: '.8rem', lineHeight: '1.9', color: 'var(--encre-douce)' } },
        listeNeg.join(' · ')))));

  const accs = accroches({ metier, ville: client.ville, nomEntreprise: client.nom_site });
  if (accs.length) {
    hote.append(h('div.carte',
      h('div.carte-tete', h('h2', 'Accroches proposees')),
      h('div.carte-corps', h('div', { style: { display: 'grid', gap: '8px' } },
        ...accs.map((a) => h('div', {
          style: { display: 'flex', gap: '10px', alignItems: 'center', padding: '9px 12px',
                   background: 'var(--surface-creux)', border: '1px solid var(--trait)', borderRadius: 'var(--r-s)' },
        },
          h('span', { style: { flex: '1' } }, a),
          h('span.mono', { style: { fontSize: '.72rem', color: a.length > 30 ? 'var(--alerte)' : 'var(--sourdine)' } },
            `${a.length}/30`),
          h('button.bt.bt-nu.bt-mini', { onclick: () => copier(a, 'Accroche copiee.') }, 'Copier')))))));
  }

  /* --- campagnes suivies --- */

  const listeCampagnes = h('div');
  dessinerCampagnes();

  hote.append(h('div.carte',
    h('div.carte-tete',
      h('h2', 'Campagnes de ce client'),
      h('span.droite', h('button.bt.bt-vif.bt-mini', { onclick: nouvelle }, 'Nouvelle campagne'))),
    h('div.carte-corps.serre', listeCampagnes)));

  async function nouvelle() {
    const nom = prompt('Nom de la campagne', `${METIERS[metier]?.libelle || 'Campagne'} — ${client.ville || ''}`.trim());
    if (!nom) return;
    try {
      const c = await D.creerCampagne({
        client_id: client.id, nom, statut: 'demandee',
        zone: client.ville || null, mots_cles: [...choisis],
        objectif: 'Appels et demandes de devis',
      });
      campagnes.unshift(c);
      oublier('campagnes');
      rafraichirPastilles();
      dessinerCampagnes();
      souffler('Campagne enregistree avec les mots-cles coches.', 'bien');
    } catch (e) {
      souffler('Creation impossible : ' + (e.message || e), 'alerte');
    }
  }

  function dessinerCampagnes() {
    vider(listeCampagnes);
    if (!campagnes.length) {
      listeCampagnes.append(h('p.vide',
        h('strong', 'Aucune campagne'),
        'Cochez les mots-cles ci-dessus puis creez une campagne : elle sera enregistree avec.'));
      return;
    }
    const corps = h('tbody');
    for (const c of campagnes) {
      corps.append(h('tr',
        h('td', h('div', { style: { fontWeight: '600' } }, c.nom),
              h('div', { style: { fontSize: '.8rem', color: 'var(--sourdine)' } },
                `${(c.mots_cles || []).length} mots-cles · ${c.zone || 'zone non definie'}`)),
        h('td', pastilleEtat(c.statut, ETATS_CAMPAGNE)),
        h('td.nb.mono', euros(c.budget_mensuel)),
        h('td', { style: { color: 'var(--sourdine)', fontSize: '.82rem' } }, depuis(c.date_creation)),
        h('td', { style: { textAlign: 'right' } },
          h('button.bt.bt-nu.bt-mini', {
            onclick: () => copier((c.mots_cles || []).join('\n'), 'Mots-cles de la campagne copies.'),
          }, 'Copier les mots-cles'))));
    }
    listeCampagnes.append(h('div.tableau-cadre', h('table',
      h('thead', h('tr', h('th', 'Campagne'), h('th', 'Etat'), h('th.nb', 'Budget/mois'), h('th', 'Creee'), h('th', ''))),
      corps)));
  }
}

async function copier(texte, message) {
  try {
    await navigator.clipboard.writeText(texte);
    souffler(message, 'bien');
  } catch {
    souffler('Copie refusee par le navigateur.', 'alerte');
  }
}

/* ==================================================================
   Onglet PROFIL
   ================================================================== */

function ongletProfil(hote, ctx) {
  const { client, profil } = ctx;
  const p = profil || {};

  const ACCES = [
    { champ: 'acces_google_business', libelle: 'Fiche Google Business',
      aide: "Le client doit vous ajouter comme gestionnaire depuis sa fiche. Deux clics de son cote, et vous pouvez repondre aux avis." },
    { champ: 'acces_google_ads', libelle: 'Compte Google Ads',
      aide: "Invitation depuis votre compte administrateur (MCC) avec son identifiant a 10 chiffres. Sa carte bancaire reste sur son compte." },
    { champ: 'acces_search_console', libelle: 'Search Console',
      aide: "Necessaire pour voir sur quelles recherches le site remonte reellement." },
  ];

  hote.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Raccordements')),
    h('div.carte-corps',
      h('p', { style: { color: 'var(--sourdine)', fontSize: '.86rem', marginBottom: '16px' } },
        "Aucun mot de passe ni cle n'est stocke ici. Ces cases ne notent que la date a laquelle l'acces a ete accorde."),
      h('div', { style: { display: 'grid', gap: '10px' } },
        ...ACCES.map((a) => ligneAcces(a, p, client.id))))));

  const champs = [
    { cle: 'google_business_url', libelle: 'Adresse de la fiche Google', type: 'url' },
    { cle: 'google_ads_id',       libelle: 'Identifiant Google Ads (10 chiffres)', type: 'text' },
    { cle: 'zone_intervention',   libelle: "Zone d'intervention", type: 'text' },
  ];

  hote.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Informations')),
    h('div.carte-corps', h('div', { style: { display: 'grid', gap: '14px', maxWidth: '520px' } },
      ...champs.map((c) => {
        const saisie = h('input', { type: c.type, value: p[c.cle] || '' });
        saisie.addEventListener('input', differer(async () => {
          try {
            await D.majProfil(client.id, { [c.cle]: saisie.value || null });
            souffler('Enregistre.', 'bien');
          } catch (e) { souffler('Enregistrement impossible.', 'alerte'); }
        }));
        return h('label.champ', { style: { margin: '0' } }, h('span', c.libelle), saisie);
      })))));
}

function ligneAcces(a, p, clientId) {
  const accorde = Boolean(p[a.champ]);
  const etat = h('span');

  function peindre(valeur) {
    vider(etat);
    etat.append(valeur
      ? h('span.etat', { 'data-ton': 'bien' }, `accorde ${depuis(valeur)}`)
      : h('span.etat', { 'data-ton': 'veille' }, 'a demander'));
  }
  peindre(p[a.champ]);

  const bouton = h('button.bt.bt-mini', { class: accorde ? 'bt bt-nu bt-mini' : 'bt bt-plein bt-mini' },
    accorde ? 'Retirer' : 'Marquer accorde');

  bouton.addEventListener('click', async () => {
    const nouvelle = p[a.champ] ? null : new Date().toISOString();
    try {
      await D.majProfil(clientId, { [a.champ]: nouvelle });
      p[a.champ] = nouvelle;
      peindre(nouvelle);
      bouton.textContent = nouvelle ? 'Retirer' : 'Marquer accorde';
      bouton.className = nouvelle ? 'bt bt-nu bt-mini' : 'bt bt-plein bt-mini';
    } catch (e) { souffler('Enregistrement impossible.', 'alerte'); }
  });

  return h('div', {
    style: { display: 'flex', gap: '14px', alignItems: 'flex-start', padding: '13px 14px',
             background: 'var(--surface-creux)', border: '1px solid var(--trait)', borderRadius: 'var(--r-s)' },
  },
    h('div', { style: { flex: '1', minWidth: '0' } },
      h('div', { style: { fontWeight: '600', display: 'flex', alignItems: 'center', gap: '9px', flexWrap: 'wrap' } },
        a.libelle, etat),
      h('div', { style: { fontSize: '.82rem', color: 'var(--sourdine)', marginTop: '3px' } }, a.aide)),
    bouton);
}

/* ==================================================================
   Onglet REGLAGES
   ================================================================== */

function ongletReglages(hote, ctx) {
  const { client } = ctx;

  const CHAMPS = [
    { cle: 'nom_site',  libelle: "Nom de l'entreprise", type: 'text' },
    { cle: 'domaine',   libelle: 'Adresse du site',     type: 'text', aide: 'exemple : rapideau-plomberie.fr' },
    { cle: 'metier',    libelle: 'Metier',              type: 'liste', options: LISTE_METIERS.map((m) => [m.cle, m.libelle]),
      aide: 'Determine les mots-cles proposes dans l onglet Campagnes.' },
    { cle: 'ville',     libelle: 'Ville',               type: 'text', aide: 'Sert a decliner les mots-cles localement.' },
    { cle: 'code_postal', libelle: 'Code postal',       type: 'text' },
    { cle: 'telephone', libelle: 'Telephone',           type: 'tel' },
    { cle: 'email',     libelle: 'E-mail',              type: 'email' },
    { cle: 'statut',    libelle: 'Statut',              type: 'liste',
      options: Object.entries(ETATS_CLIENT).map(([c, e]) => [c, e.libelle]) },
    { cle: 'formule',   libelle: 'Formule',             type: 'text', aide: 'exemple : Vitrine 49 EUR/mois' },
    { cle: 'tarif_mensuel', libelle: 'Tarif mensuel (EUR)', type: 'number' },
    { cle: 'date_mise_en_ligne', libelle: 'Mise en ligne', type: 'date' },
    { cle: 'acces_client', libelle: 'Ce que le client peut modifier', type: 'liste',
      options: [['aucun', 'Rien — je gere tout'],
                ['essentiel', 'Essentiel — horaires, coordonnees, annonce'],
                ['complet', 'Complet — essentiel + carte et prix']],
      aide: "Un restaurant gere sa carte ; un plombier n'en a pas. On decide par activite, pas champ par champ." },
  ];

  const grille = h('div', { style: { display: 'grid', gap: '15px', gridTemplateColumns: 'repeat(auto-fit,minmax(248px,1fr))' } });

  for (const c of CHAMPS) {
    let saisie;
    if (c.type === 'liste') {
      saisie = h('select', ...c.options.map(([v, l]) =>
        h('option', { value: v, selected: (client[c.cle] || '') === v }, l)));
    } else {
      saisie = h('input', { type: c.type, value: client[c.cle] ?? '' });
    }

    const ecrire = async () => {
      const brut = saisie.value;
      const valeur = brut === '' ? null : (c.type === 'number' ? Number(brut) : brut);
      try {
        await D.majClient(client.id, { [c.cle]: valeur });
        client[c.cle] = valeur;
        oublier('clients');
        souffler('Enregistre.', 'bien');
      } catch (e) { souffler('Enregistrement impossible : ' + (e.message || e), 'alerte'); }
    };

    saisie.addEventListener(c.type === 'liste' ? 'change' : 'input',
      c.type === 'liste' ? ecrire : differer(ecrire));

    grille.append(h('label.champ', { style: { margin: '0' } },
      h('span', c.libelle),
      saisie,
      c.aide ? h('small', { style: { display: 'block', marginTop: '5px', color: 'var(--sourdine)', fontSize: '.78rem' } }, c.aide) : null));
  }

  hote.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Fiche du client')),
    h('div.carte-corps', grille)));

  const notes = h('textarea', { rows: 6, value: client.notes || '', placeholder: 'Ce dont on se souvient : preferences, historique, sujets a eviter...' });
  notes.addEventListener('input', differer(async () => {
    try {
      await D.majClient(client.id, { notes: notes.value || null });
      client.notes = notes.value;
      souffler('Note enregistree.', 'bien');
    } catch { souffler('Enregistrement impossible.', 'alerte'); }
  }));

  hote.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Notes internes'),
      h('span.droite', h('span', { style: { color: 'var(--sourdine)', fontSize: '.8rem' } }, 'jamais visible par le client'))),
    h('div.carte-corps', notes)));

  hote.append(h('div.carte',
    h('div.carte-tete', h('h2', 'Suivi du site')),
    h('div.carte-corps',
      h('div', { style: { display: 'grid', gap: '9px' } },
        info('Identifiant technique', h('code.mono', { style: { fontSize: '.78rem' } }, client.id)),
        info('Client cree le', client.date_creation ? dateLongue(client.date_creation) : '—'),
        info('Visites (30 j)', nombre(ctx.visites.length)),
        info('Demandes recues', nombre(ctx.demandes.length))))));
}

function info(etiquette, valeur) {
  return h('div', {
    style: { display: 'flex', gap: '14px', justifyContent: 'space-between',
             padding: '9px 0', borderBottom: '1px solid var(--trait)', flexWrap: 'wrap' },
  },
    h('span', { style: { color: 'var(--sourdine)', fontSize: '.86rem' } }, etiquette),
    typeof valeur === 'string' ? h('span', { style: { fontWeight: '550' } }, valeur) : valeur);
}
