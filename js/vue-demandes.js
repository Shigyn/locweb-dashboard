// ===================================================================
//  Toutes les demandes, tous clients confondus.
//
//  Vue transversale : la fiche client montre les demandes d'UN client,
//  celle-ci montre ce qui attend une reponse CE MATIN, quel que soit le
//  client. C'est la vue de la boite de reception, pas celle du dossier.
// ===================================================================

import { h, vider, nombre, differer, mesure } from './outils.js';
import * as D from './donnees.js';
import { charger, oublier, tete, rafraichirPastilles } from './app.js';
import { tableauDemandes } from './vue-client.js';

const FILTRES = [
  { cle: 'a_traiter', libelle: 'A traiter' },
  { cle: 'toutes',    libelle: 'Toutes' },
];

export async function rendre(page) {
  const [demandes, clients] = await Promise.all([
    charger('demandes', () => D.listerDemandes({})),
    charger('clients',  () => D.listerClients()),
  ]);

  const noms = new Map(clients.map((c) => [c.id, c.nom_site || 'Sans nom']));

  const nouvelles = demandes.filter((d) => (d.statut || 'nouvelle') === 'nouvelle');

  tete(
    h('h1', 'Demandes'),
    h('button.bt.bt-nu', { onclick: () => { oublier(); location.reload(); } }, 'Actualiser'),
  );

  page.append(h('div.synthese',
    mesure('horloge', 'A traiter', nouvelles.length, nouvelles.length ? 'action' : 'bien',
      nouvelles.length ? 'sur l ensemble des clients' : 'tout est traite'),
    mesure('demandes', 'Recues au total', demandes.length, '', 'tous clients'),
  ));

  const zone = h('div');
  const barre = h('div.onglets', { role: 'tablist' });
  const recherche = h('input', {
    type: 'text', placeholder: 'Filtrer par nom, ville, besoin...',
    style: { maxWidth: '300px', marginBottom: '14px' },
    oninput: differer((e) => dessiner(actif, e.target.value), 180),
  });

  let actif = 'a_traiter';
  const boutons = FILTRES.map((f) => {
    const n = f.cle === 'a_traiter' ? nouvelles.length : demandes.length;
    const b = h('button', { role: 'tab', 'aria-selected': String(f.cle === actif), onclick: () => {
      actif = f.cle;
      boutons.forEach((x) => x.b.setAttribute('aria-selected', String(x.cle === actif)));
      dessiner(actif, recherche.value);
    } }, f.libelle, h('span.compte', nombre(n)));
    barre.append(b);
    return { cle: f.cle, b };
  });

  page.append(barre, recherche, zone);

  function dessiner(filtre, texte = '') {
    const t = texte.toLowerCase().trim();
    let liste = filtre === 'a_traiter' ? demandes.filter((d) => (d.statut || 'nouvelle') === 'nouvelle') : demandes;
    if (t) {
      liste = liste.filter((d) => [d.nom, d.ville, d.besoin, noms.get(d.client_id)]
        .some((x) => (x || '').toLowerCase().includes(t)));
    }
    vider(zone);
    if (!liste.length) {
      zone.append(h('div.carte', h('p.vide',
        h('strong', filtre === 'a_traiter' ? 'Rien a traiter' : 'Aucune demande'),
        filtre === 'a_traiter' ? 'Toutes les demandes ont ete prises en charge.' : 'Aucune demande ne correspond.')));
      return;
    }
    zone.append(h('div.carte', h('div.carte-corps.serre',
      tableauDemandes(liste, (clientId) => h('a', {
        href: `#/client/${clientId}/demandes`, style: { fontWeight: '600', textDecoration: 'none' },
      }, noms.get(clientId) || 'Client')))));
  }

  dessiner(actif);

  // La liste vient d'etre affichee : si l'operateur revient depuis le
  // rail, les pastilles doivent deja refleter ce qu'il vient de voir.
  rafraichirPastilles();
}
