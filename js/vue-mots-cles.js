// ===================================================================
//  Banque de mots-cles — vue libre, sans client selectionne.
//
//  Sert a deux choses : explorer ce que la banque propose pour un
//  metier avant d'avoir un client en face (prospection, devis), et
//  servir de reference quand on veut juste relire la liste. La version
//  qui compte reellement, celle attachee a une campagne, vit dans
//  l'onglet Campagnes de chaque fiche client.
// ===================================================================

import { h, vider, souffler } from './outils.js';
import { LISTE_METIERS, METIERS, suggerer, negatifs, accroches } from './metiers.js';
import { tete } from './app.js';

const INTENTIONS = { urgence: 'Urgence', projet: 'Projet', info: 'Info', marque: 'Marque' };

export async function rendre(page) {
  tete(h('h1', 'Mots-cles par metier'));

  const metierSelect = h('select', ...LISTE_METIERS.map((m) => h('option', { value: m.cle }, m.libelle)));
  const villeChamp = h('input', { type: 'text', placeholder: 'Ville (optionnel)', style: { maxWidth: '220px' } });
  const entrepriseChamp = h('input', { type: 'text', placeholder: 'Nom d entreprise (optionnel)', style: { maxWidth: '240px' } });

  page.append(h('div.carte',
    h('div.carte-corps', h('div', {
      style: { display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'flex-end' },
    },
      champ('Metier', metierSelect),
      champ('Ville', villeChamp),
      champ('Entreprise', entrepriseChamp),
    ))));

  const zone = h('div');
  page.append(zone);

  const redessiner = () => dessiner(zone, {
    metier: metierSelect.value,
    ville: villeChamp.value.trim(),
    nomEntreprise: entrepriseChamp.value.trim(),
  });

  metierSelect.addEventListener('change', redessiner);
  villeChamp.addEventListener('input', debounce(redessiner, 250));
  entrepriseChamp.addEventListener('input', debounce(redessiner, 250));

  redessiner();
}

function champ(libelle, el) {
  return h('label', { style: { display: 'flex', flexDirection: 'column', gap: '6px' } },
    h('span', { style: { fontSize: '.74rem', fontWeight: '600', letterSpacing: '.07em', textTransform: 'uppercase', color: 'var(--sourdine)' } }, libelle),
    el);
}

function debounce(fn, delai) {
  let t;
  return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), delai); };
}

function dessiner(zone, params) {
  vider(zone);
  const props = suggerer(params);
  const grille = h('div.grille-mots');
  props.forEach((p) => grille.append(h('div.mot-cle', { 'data-intention': p.intention },
    h('span.texte', p.texte), h('span.intention', INTENTIONS[p.intention]))));

  zone.append(h('div.carte',
    h('div.carte-tete',
      h('h2', `${props.length} mots-cles suggeres`),
      h('span.droite', h('button.bt.bt-plein.bt-mini', {
        onclick: () => copier(props.map((p) => p.texte).join('\n')),
      }, 'Copier tout'))),
    h('div.carte-corps', grille)));

  const listeNeg = negatifs(params.metier);
  zone.append(h('div.carte',
    h('div.carte-tete',
      h('h2', 'A exclure'),
      h('span.droite', h('button.bt.bt-plein.bt-mini', { onclick: () => copier(listeNeg.join('\n')) }, 'Copier'))),
    h('div.carte-corps', h('p', { style: { fontFamily: 'var(--mono)', fontSize: '.8rem', lineHeight: '1.9', color: 'var(--encre-douce)' } },
      listeNeg.join(' · ')))));

  const accs = accroches(params);
  if (accs.length) {
    zone.append(h('div.carte',
      h('div.carte-tete', h('h2', 'Accroches')),
      h('div.carte-corps', h('div', { style: { display: 'grid', gap: '8px' } },
        ...accs.map((a) => h('div', {
          style: { display: 'flex', gap: '10px', alignItems: 'center', padding: '9px 12px',
                   background: 'var(--surface-creux)', border: '1px solid var(--trait)', borderRadius: 'var(--r-s)' },
        }, h('span', { style: { flex: '1' } }, a), h('button.bt.bt-nu.bt-mini', { onclick: () => copier(a) }, 'Copier')))))));
  }
}

async function copier(texte) {
  try { await navigator.clipboard.writeText(texte); souffler('Copie.', 'bien'); }
  catch { souffler('Copie refusee par le navigateur.', 'alerte'); }
}
