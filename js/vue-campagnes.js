// ===================================================================
//  Campagnes — vue transversale.
//
//  La construction reelle se fait dans Google Ads ; ici c'est le
//  guichet (une demande arrive, on la prepare) et le tableau de bord
//  (ou en est chaque campagne). Jamais de cle d'API stockee : l'acces
//  passe par le compte administrateur (MCC).
// ===================================================================

import { h, vider, nombre, euros, depuis, pastilleEtat, ETATS_CAMPAGNE, differer, souffler, certain, mesure } from './outils.js';
import * as D from './donnees.js';
import { charger, oublier, tete, rafraichirPastilles } from './app.js';

export async function rendre(page) {
  const [campagnes, clients] = await Promise.all([
    charger('campagnes', () => D.listerCampagnes()),
    charger('clients',   () => D.listerClients()),
  ]);

  const noms = new Map(clients.map((c) => [c.id, c.nom_site || 'Sans nom']));

  tete(
    h('h1', 'Campagnes'),
    h('a.bt.bt-plein', { href: '#/mots-cles' }, 'Banque de mots-cles'),
    h('button.bt.bt-nu', { onclick: () => { oublier(); location.reload(); } }, 'Actualiser'),
  );

  const demandees = campagnes.filter((c) => c.statut === 'demandee');
  const actives = campagnes.filter((c) => c.statut === 'active');
  const budgetActif = actives.reduce((s, c) => s + Number(c.budget_mensuel || 0), 0);

  page.append(h('div.synthese',
    mesure('campagne', 'A preparer', demandees.length, demandees.length ? 'action' : 'bien', 'demandees, pas encore parties'),
    mesure('reussite', 'Actives', actives.length, 'bien', 'en cours dans Google Ads'),
    mesure('revenu', 'Budget actif', euros(budgetActif), '', 'cumule / mois'),
  ));

  if (!campagnes.length) {
    page.append(h('div.carte', h('p.vide',
      h('strong', 'Aucune campagne pour l instant'),
      "Une campagne se cree depuis l'onglet Campagnes d'une fiche client, avec les mots-cles deja coches.")));
    return;
  }

  const zone = h('div');
  page.append(zone);
  dessiner();

  function dessiner() {
    vider(zone);
    const corps = h('tbody');
    for (const c of [...campagnes].sort((a, b) => RANG[a.statut] - RANG[b.statut] || b.date_creation.localeCompare(a.date_creation))) {
      const select = h('select', { style: { minWidth: '150px' },
        onchange: async (e) => {
          const avant = c.statut;
          try {
            await D.majCampagne(c.id, { statut: e.target.value });
            c.statut = e.target.value;
            oublier('campagnes');
            rafraichirPastilles();
            souffler('Statut mis a jour.', 'bien');
            dessiner();
          } catch { e.target.value = avant; souffler('Enregistrement impossible.', 'alerte'); }
        } },
        ...Object.entries(ETATS_CAMPAGNE).map(([cle, e]) => h('option', { value: cle, selected: c.statut === cle }, e.libelle)));

      const budget = h('input', { type: 'number', min: '0', step: '10', value: c.budget_mensuel ?? '',
        placeholder: '—', style: { width: '90px', textAlign: 'right' } });
      budget.addEventListener('input', differer(async () => {
        try {
          await D.majCampagne(c.id, { budget_mensuel: budget.value === '' ? null : Number(budget.value) });
          c.budget_mensuel = budget.value === '' ? null : Number(budget.value);
          oublier('campagnes');
        } catch { souffler('Enregistrement impossible.', 'alerte'); }
      }));

      corps.append(h('tr',
        h('td', h('a', { href: `#/client/${c.client_id}/campagnes`, style: { fontWeight: '600', textDecoration: 'none' } },
          noms.get(c.client_id) || 'Client')),
        h('td', h('div', c.nom), h('div', { style: { fontSize: '.8rem', color: 'var(--sourdine)' } },
          `${(c.mots_cles || []).length} mots-cles${c.zone ? ' · ' + c.zone : ''}`)),
        h('td', select),
        h('td', budget),
        h('td', { style: { color: 'var(--sourdine)', fontSize: '.82rem' } }, depuis(c.date_creation)),
        h('td', h('button.bt.bt-nu.bt-mini', {
          title: 'Supprimer cette campagne',
          onclick: async () => {
            if (!certain(`Supprimer la campagne "${c.nom}" ? Cette action est definitive.`)) return;
            try {
              await D.supprimerCampagne(c.id);
              campagnes.splice(campagnes.indexOf(c), 1);
              oublier('campagnes');
              rafraichirPastilles();
              souffler('Campagne supprimee.', 'veille');
              dessiner();
            } catch { souffler('Suppression impossible.', 'alerte'); }
          },
        }, 'Supprimer')),
      ));
    }

    zone.append(h('div.carte',
      h('div.carte-tete', h('h2', 'Toutes les campagnes')),
      h('div.carte-corps.serre', h('div.tableau-cadre', h('table',
        h('thead', h('tr', h('th', 'Client'), h('th', 'Campagne'), h('th', 'Etat'), h('th', 'Budget/mois'), h('th', 'Creee'), h('th', ''))),
        corps)))));
  }
}

const RANG = { demandee: 0, en_preparation: 1, active: 2, en_pause: 3, terminee: 4 };
