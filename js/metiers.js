// ===================================================================
//  Banque de mots-cles par metier.
//
//  Elle vit dans un fichier et non en base : c'est du savoir-faire, pas
//  de la donnee client. On l'enrichit en modifiant ce fichier, elle est
//  versionnee avec le reste, et le client ne peut ni la voir ni la
//  casser. Une table aurait apporte un aller-retour reseau et un
//  formulaire d'edition pour aucun benefice.
//
//  Un mot-cle porte toujours une INTENTION, parce que c'est elle qui
//  decide de l'enchere :
//    urgence — la personne a un probleme maintenant. Cher, mais ca
//              convertit au telephone dans l'heure.
//    projet  — elle compare, elle prevoit. Plus long, plus gros panier.
//    info    — elle s'informe. A n'acheter qu'en remarketing.
//    marque  — elle cherche l'entreprise par son nom. Presque gratuit,
//              a prendre systematiquement pour ne pas laisser un
//              concurrent se placer dessus.
// ===================================================================

/* Negatifs communs a tous les metiers locaux. Ils ne rapportent rien et
   consomment le budget : quelqu'un qui cherche un salaire ou une
   formation ne deviendra jamais client. C'est la premiere economie
   d'une campagne, et celle qu'on oublie le plus souvent. */
export const NEGATIFS_COMMUNS = [
  'emploi', 'offre emploi', 'recrutement', 'salaire', 'formation', 'cap', 'bts',
  'stage', 'apprentissage', 'devenir', 'metier', 'definition', 'wikipedia',
  'gratuit', 'tuto', 'tutoriel', 'youtube', 'pdf', 'occasion', 'leboncoin',
  'auto entrepreneur', 'statut', 'franchise', 'reprise', 'a vendre',
];

export const METIERS = {

  plombier: {
    libelle: 'Plombier / chauffagiste',
    urgences: [
      'depannage plomberie', 'fuite d eau', 'urgence plomberie', 'plombier urgence',
      'canalisation bouchee', 'debouchage canalisation', 'wc bouche', 'chauffe eau en panne',
      'fuite chauffe eau', 'degat des eaux', 'plombier dimanche', 'plombier nuit',
    ],
    projets: [
      'installation salle de bain', 'renovation salle de bain', 'remplacement chauffe eau',
      'installation chaudiere', 'entretien chaudiere', 'pompe a chaleur',
      'installation douche italienne', 'plomberie neuf', 'devis plomberie',
    ],
    infos: ['prix depannage plomberie', 'tarif plombier heure'],
    negatifs: ['pieces detachees', 'bricolage', 'castorama', 'leroy merlin'],
    accroches: [
      'Depannage sous 1 h — {ville} et alentours',
      'Devis gratuit, tarif annonce avant intervention',
      'Artisan {ville} — 7 j/7, urgences acceptees',
    ],
  },

  electricien: {
    libelle: 'Electricien',
    urgences: [
      'depannage electrique', 'panne electrique', 'electricien urgence', 'court circuit',
      'coupure courant', 'tableau electrique en panne', 'electricien dimanche',
    ],
    projets: [
      'mise aux normes electrique', 'renovation electrique', 'tableau electrique',
      'installation borne de recharge', 'installation domotique', 'devis electricite',
      'consuel', 'diagnostic electrique vente',
    ],
    infos: ['prix mise aux normes electrique', 'norme nf c 15-100'],
    negatifs: ['schema', 'branchement soi meme', 'leroy merlin'],
    accroches: [
      'Electricien certifie — intervention rapide a {ville}',
      'Mise aux normes, devis gratuit sous 24 h',
    ],
  },

  paysagiste: {
    libelle: 'Paysagiste / jardinier',
    urgences: [
      'elagage urgent', 'abattage arbre', 'debroussaillage obligatoire',
      'nettoyage terrain', 'jardinier urgent',
    ],
    projets: [
      'creation de jardin', 'amenagement exterieur', 'amenagement paysager',
      'pose de gazon', 'gazon synthetique', 'terrasse bois', 'cloture jardin',
      'systeme arrosage automatique', 'taille de haie', 'entretien jardin annuel',
      'paysagiste devis', 'mur vegetal', 'bassin de jardin',
    ],
    infos: ['prix entretien jardin', 'credit impot jardinage'],
    negatifs: ['graines', 'jardinerie', 'plantes en ligne', 'gamm vert'],
    accroches: [
      'Paysagiste a {ville} — devis gratuit sous 48 h',
      'Entretien annuel : credit d impot 50 %',
      'Creation, entretien, elagage — {ville} et 20 km',
    ],
  },

  restaurant: {
    libelle: 'Restaurant',
    urgences: ['restaurant ouvert maintenant', 'restaurant ouvert dimanche', 'reserver table ce soir'],
    projets: [
      'restaurant', 'ou manger', 'meilleur restaurant', 'restaurant midi',
      'menu du jour', 'restaurant terrasse', 'restaurant groupe', 'reserver restaurant',
      'restaurant en famille', 'plat a emporter', 'traiteur',
    ],
    infos: ['carte restaurant', 'horaires restaurant'],
    negatifs: ['recette', 'marmiton', 'thermomix', 'franchise', 'fonds de commerce'],
    accroches: [
      'Cuisine maison a {ville} — reservation en ligne',
      'Menu du jour a partir de {prix} — midi en semaine',
    ],
  },

  snack: {
    libelle: 'Snack / burger / pizzeria',
    urgences: ['livraison burger', 'snack ouvert maintenant', 'commander a emporter'],
    projets: [
      'burger', 'meilleur burger', 'pizzeria', 'pizza a emporter', 'kebab',
      'tacos', 'snack', 'fast food', 'burger maison', 'commander en ligne',
      'livraison pizza', 'restauration rapide',
    ],
    infos: ['carte burger', 'prix menu burger'],
    negatifs: ['recette', 'mcdo', 'burger king', 'franchise', 'materiel'],
    accroches: [
      'Burgers smashes a la commande — {ville}',
      'A emporter en 9 minutes — commande par telephone',
    ],
  },

  coiffeur: {
    libelle: 'Coiffeur / barbier',
    urgences: ['coiffeur sans rendez vous', 'coiffeur ouvert aujourd hui'],
    projets: [
      'coiffeur', 'salon de coiffure', 'barbier', 'coloration cheveux',
      'balayage', 'lissage bresilien', 'extension cheveux', 'coiffure mariage',
      'coupe homme', 'barbe',
    ],
    infos: ['prix coiffeur', 'tarif balayage'],
    negatifs: ['emploi', 'academie', 'materiel coiffure', 'produits'],
    accroches: [
      'Salon a {ville} — rendez-vous en ligne 7 j/7',
      'Coupe, couleur, barbe — sans rendez-vous possible',
    ],
  },

  macon: {
    libelle: 'Macon / gros oeuvre',
    urgences: ['reparation mur fissure', 'urgence maconnerie'],
    projets: [
      'maconnerie', 'extension maison', 'construction garage', 'dalle beton',
      'mur de cloture', 'terrasse beton', 'renovation facade', 'ravalement facade',
      'ouverture mur porteur', 'devis maconnerie', 'artisan macon',
    ],
    infos: ['prix extension maison m2', 'permis de construire'],
    negatifs: ['materiaux', 'point p', 'brico depot', 'parpaing prix'],
    accroches: [
      'Macon a {ville} — devis gratuit, chantier propre',
      'Extension, terrasse, cloture — garantie decennale',
    ],
  },

  peintre: {
    libelle: 'Peintre en batiment',
    urgences: ['peintre disponible rapidement'],
    projets: [
      'peintre en batiment', 'peinture interieure', 'peinture appartement',
      'ravalement facade', 'pose papier peint', 'enduit decoratif',
      'renovation peinture', 'devis peinture', 'peintre decorateur',
    ],
    infos: ['prix peinture m2', 'tarif peintre'],
    negatifs: ['pot de peinture', 'nuancier', 'tollens', 'leroy merlin'],
    accroches: [
      'Peintre a {ville} — interieur et facade, devis gratuit',
      'Chantier propre, delais tenus, garantie decennale',
    ],
  },

  menuisier: {
    libelle: 'Menuisier',
    urgences: ['reparation volet', 'depannage porte'],
    projets: [
      'menuisier', 'fenetre sur mesure', 'porte d entree', 'volet roulant',
      'veranda', 'pergola', 'placard sur mesure', 'cuisine sur mesure',
      'parquet', 'escalier bois', 'devis menuiserie',
    ],
    infos: ['prix fenetre double vitrage', 'aide renovation fenetre'],
    negatifs: ['bricolage', 'plan gratuit', 'lapeyre', 'ikea'],
    accroches: [
      'Menuisier a {ville} — sur mesure, pose comprise',
      'Fenetres, volets, dressing — devis sous 48 h',
    ],
  },

  garagiste: {
    libelle: 'Garage / mecanicien',
    urgences: [
      'depannage auto', 'remorquage', 'panne voiture', 'garage ouvert maintenant',
      'reparation rapide voiture',
    ],
    projets: [
      'garage automobile', 'revision voiture', 'vidange', 'changement embrayage',
      'distribution', 'controle technique contre visite', 'reparation carrosserie',
      'climatisation voiture', 'pneus', 'diagnostic electronique',
    ],
    infos: ['prix vidange', 'tarif revision'],
    negatifs: ['pieces auto', 'oscaro', 'occasion', 'voiture a vendre'],
    accroches: [
      'Garage a {ville} — devis avant travaux, toutes marques',
      'Revision, freins, distribution — rendez-vous sous 48 h',
    ],
  },

  esthetique: {
    libelle: 'Institut de beaute / esthetique',
    urgences: ['institut sans rendez vous'],
    projets: [
      'institut de beaute', 'epilation definitive', 'soin du visage', 'manucure',
      'pose ongles', 'extension cils', 'massage', 'epilation laser',
      'onglerie', 'soin corps', 'maquillage mariage',
    ],
    infos: ['prix epilation laser', 'tarif soin visage'],
    negatifs: ['emploi', 'formation esthetique', 'materiel', 'produits pro'],
    accroches: [
      'Institut a {ville} — reservation en ligne',
      'Soins visage, epilation, ongles — 7 j/7',
    ],
  },

  ecommerce: {
    libelle: 'Boutique en ligne',
    urgences: ['livraison rapide'],
    projets: [
      'acheter en ligne', 'boutique en ligne', 'livraison france',
      'fait main', 'artisanal', 'made in france', 'cadeau original',
    ],
    infos: ['comparatif', 'avis'],
    negatifs: ['gratuit', 'telecharger', 'contrefacon', 'grossiste', 'dropshipping'],
    accroches: [
      'Livraison en 48 h — retours gratuits',
      'Fabrique en France — expedition sous 24 h',
    ],
  },

  autre: {
    libelle: 'Autre activite',
    urgences: [], projets: [], infos: [], negatifs: [],
    accroches: ['{metier} a {ville} — devis gratuit'],
  },
};

/* ---------- generation ---------- */

const GABARITS = [
  { forme: (p, v) => `${p} ${v}`,       poids: 10 },
  { forme: (p, v) => `${p} a ${v}`,     poids:  8 },
  { forme: (p, v) => `${p} pres de ${v}`, poids: 5 },
];

/**
 * Croise les prestations d'un metier avec la ville du client.
 *
 * Le tri n'est pas cosmetique : il place en tete ce qui converti le
 * mieux pour un artisan local — l'urgence d'abord, le projet ensuite,
 * l'information en dernier. C'est l'ordre dans lequel on veut depenser.
 *
 * @returns {{texte:string, intention:string, score:number}[]}
 */
export function suggerer({ metier, ville, nomEntreprise = '', codePostal = '' }) {
  const fiche = METIERS[metier] || METIERS.autre;
  const lieu = (ville || '').trim();
  const sortie = [];
  const vus = new Set();

  const ajouter = (texte, intention, score) => {
    const cle = texte.toLowerCase().replace(/\s+/g, ' ').trim();
    if (!cle || vus.has(cle)) return;
    vus.add(cle);
    sortie.push({ texte: cle, intention, score });
  };

  const familles = [
    { liste: fiche.urgences || [], intention: 'urgence', base: 100 },
    { liste: fiche.projets  || [], intention: 'projet',  base:  70 },
    { liste: fiche.infos    || [], intention: 'info',    base:  30 },
  ];

  for (const { liste, intention, base } of familles) {
    for (const prestation of liste) {
      if (lieu) {
        for (const g of GABARITS) ajouter(g.forme(prestation, lieu), intention, base + g.poids);
      } else {
        ajouter(prestation, intention, base);
      }
    }
  }

  // Le nom de l'entreprise : quasi gratuit en enchere, et si on ne le
  // prend pas un concurrent peut s'afficher au-dessus quand quelqu'un
  // cherche le client par son nom.
  if (nomEntreprise) {
    ajouter(nomEntreprise, 'marque', 130);
    if (lieu) ajouter(`${nomEntreprise} ${lieu}`, 'marque', 128);
  }

  // Le code postal capte les recherches tapees au plus court, souvent
  // depuis un telephone.
  if (codePostal && lieu) {
    const premiere = (fiche.urgences || fiche.projets || [])[0];
    if (premiere) ajouter(`${premiere} ${codePostal}`, 'urgence', 95);
  }

  return sortie.sort((a, b) => b.score - a.score || a.texte.localeCompare(b.texte));
}

export function negatifs(metier) {
  const fiche = METIERS[metier] || METIERS.autre;
  return [...new Set([...NEGATIFS_COMMUNS, ...(fiche.negatifs || [])])].sort();
}

export function accroches({ metier, ville, nomEntreprise }) {
  const fiche = METIERS[metier] || METIERS.autre;
  return (fiche.accroches || []).map((a) => a
    .replace(/\{ville\}/g, ville || 'votre ville')
    .replace(/\{metier\}/g, fiche.libelle)
    .replace(/\{entreprise\}/g, nomEntreprise || '')
    .replace(/\{prix\}/g, '00 EUR'));
}

export const LISTE_METIERS = Object.entries(METIERS)
  .map(([cle, m]) => ({ cle, libelle: m.libelle }))
  .sort((a, b) => (a.cle === 'autre' ? 1 : b.cle === 'autre' ? -1 : a.libelle.localeCompare(b.libelle)));
