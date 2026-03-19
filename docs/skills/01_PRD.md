# PRD — ShootHelper

> **Skill 01/22** · Product Requirements Document
> Version 1.0 · Mars 2026

---

## 1. Problème

Quand on débute en photographie/vidéo et qu'on shoote en mode manuel, on est confronté à trois problèmes simultanés :

1. **On ne sait pas quels réglages utiliser.** ISO, ouverture, vitesse, balance des blancs, mode de mesure, mode AF… Les combinaisons sont infinies et les "règles" changent selon le contexte.
2. **On ne comprend pas pourquoi.** Même quand un tuto donne des réglages, il ne t'explique pas le raisonnement derrière pour *ta* situation précise.
3. **On ne sait pas où trouver le réglage dans son appareil.** Chaque marque (Sony, Canon, Nikon, Fuji…) a son propre arbre de menus, ses propres noms de paramètres, et potentiellement dans une langue différente selon le firmware. Un débutant perd un temps fou à chercher "AF-C" dans les menus de son Sony alors que chez Canon ça s'appelle "AI Servo".

**Aucune app existante ne résout ces trois problèmes ensemble**, et surtout aucune ne donne le chemin exact dans les menus de l'appareil, dans la langue configurée.

---

## 2. Solution

**ShootHelper** (nom de travail) est une application mobile qui :

- Connaît ton appareil photo et ton/tes objectif(s)
- Te demande de décrire précisément ta scène et ce que tu veux capturer
- Calcule les réglages optimaux adaptés aux capacités de ton matériel
- Explique *pourquoi* chaque réglage est recommandé pour ta situation
- Te montre le **chemin exact dans les menus de ton appareil**, dans la langue de ton firmware

---

## 3. Utilisateur cible

### Persona principal : Le débutant en manuel

- Possède un appareil photo hybride ou reflex (pas smartphone)
- A décidé de quitter le mode auto pour apprendre le manuel
- Comprend vaguement ce que sont ISO/ouverture/vitesse mais ne sait pas les combiner
- Shoote en extérieur (paysage, street, portrait, astro, sunset) et veut progresser
- Frustré par les tutos génériques qui disent "ça dépend"
- Utilise son téléphone sur le terrain, souvent sans réseau (randonnée, plage, montagne)

### Persona secondaire : L'intermédiaire curieux

- Maîtrise les bases mais veut optimiser pour des situations spécifiques
- Utilise l'app pour vérifier ses intuitions ou découvrir des réglages qu'il n'utilise pas
- Intéressé par les explications détaillées du "pourquoi"

---

## 4. Core Value Proposition

**"Dis-moi ce que tu veux shooter, je te dis exactement quoi régler et où le trouver."**

Le différenciateur unique est le **Menu Navigation Mapper** : aucun concurrent ne te guide physiquement dans les menus de ton appareil spécifique, dans ta langue.

---

## 5. Feature Set — MVP vs V2+

### 5.1. MVP (Version 1.0)

Le MVP est l'app minimale qui délivre la promesse core. Tout ce qui est listé ici est **nécessaire** au lancement.

#### A. Onboarding & Gear Setup

| Feature | Description |
|---------|-------------|
| Sélection appareil | Liste de boîtiers supportés, recherche par marque/modèle |
| Sélection objectif(s) | Liste d'objectifs compatibles avec le boîtier sélectionné |
| Langue firmware | Choix de la langue configurée sur l'appareil (FR, EN, DE, JP…) |
| Téléchargement data pack | Download des données du boîtier + objectif(s) pour usage offline |
| Profil gear sauvegardé | Le setup est mémorisé, pas besoin de le refaire |

**Boîtiers supportés au lancement MVP :**

Objectif : couvrir les boîtiers les plus populaires chez les débutants/intermédiaires.

- **Sony** : A6700, A6400, A7 IV, A7C II
- **Canon** : R50, R10, R7, R6 Mark II
- **Nikon** : Z50 II, Z30, Zf, Z6 III
- **Fujifilm** : X-T5, X-S20

*(14 boîtiers — suffisant pour couvrir ~70% du marché débutant/intermédiaire hybride)*

#### B. Scene Input (Description de scène)

L'utilisateur décrit sa scène via un système structuré, pas du texte libre. Le système est progressif : on commence simple, on peut aller deep.

**Paramètres obligatoires (Niveau 1 — Le minimum) :**

| Paramètre | Options (exemples) |
|-----------|-------------------|
| Type de shoot | Photo / Vidéo |
| Environnement | Extérieur jour, Extérieur nuit, Intérieur éclairé, Intérieur sombre, Studio |
| Sujet | Paysage, Portrait, Street, Architecture, Macro, Astro, Sport/Action, Animalier, Produit |
| Intention | Netteté maximale, Flou d'arrière-plan, Figer le mouvement, Filé de mouvement, Low-light performance |

**Paramètres optionnels (Niveau 2 — Aller plus loin) :**

| Paramètre | Options (exemples) |
|-----------|-------------------|
| Conditions lumière | Soleil direct, Ombre, Couvert, Golden hour, Blue hour, Nuit étoilée, Éclairage artificiel (néon, tungstène, LED) |
| Mouvement sujet | Immobile, Lent, Rapide, Très rapide (sport, oiseaux) |
| Distance sujet | Très proche (<50cm), Proche (1-3m), Moyen (3-10m), Loin (>10m), Infini |
| Résultat souhaité (mood) | Dramatique, Doux/pastel, High contrast, Naturel, Silhouette |
| Support | Main levée, Trépied, Monopode, Gimbal |
| Contraintes | "Je ne veux pas dépasser ISO 3200", "Je veux au moins 1/500s" |

**Paramètres avancés (Niveau 3 — Deep dive) :**

| Paramètre | Options (exemples) |
|-----------|-------------------|
| Température couleur cible | Valeur Kelvin ou preset |
| Profondeur de champ souhaitée | Shallow / Medium / Deep + possibilité de spécifier en mètres |
| Zone AF souhaitée | Centre, Zone large, Suivi, Eye-AF |
| Bracketing | Exposition / Focus |
| Format fichier | RAW, JPEG, RAW+JPEG |

#### C. Settings Engine (Moteur de calcul)

Le moteur prend en entrée : gear + scène → sort les réglages optimaux.

**Réglages calculés :**

| Réglage | Toujours | Détail |
|---------|----------|--------|
| Mode exposition | ✅ | M, A, S, P — et pourquoi ce mode pour cette situation |
| Ouverture (f/) | ✅ | Limité par les capacités de l'objectif |
| Vitesse d'obturation | ✅ | Respecte la règle du "1/focale" si main levée, ajusté au sujet |
| ISO | ✅ | Optimisé bruit vs exposition, respecte les limites du capteur |
| Balance des blancs | ✅ | Auto ou valeur Kelvin selon la situation |
| Mode autofocus | ✅ | AF-S/AF-C/MF selon le sujet |
| Zone AF | ✅ | Adapté au sujet et à la situation |
| Mode de mesure | ✅ | Matricielle/Spot/Pondérée selon la scène |
| Compensation exposition | Si pertinent | Scènes à fort contraste, neige, contre-jour |
| Format fichier | ✅ | RAW recommandé par défaut avec explication |
| Stabilisation | Si dispo | On/Off selon trépied ou non |

**Logique du moteur :**

Le moteur fonctionne par **arbres de décision pondérés**, pas par IA/ML. Les règles sont déterministes et auditables :

1. Déterminer l'exposition cible (EV) selon l'environnement
2. Prioriser selon l'intention (ex : flou → ouverture d'abord, figer mouvement → vitesse d'abord)
3. Calculer le triangle d'exposition en respectant les limites du matériel
4. Ajuster selon les contraintes utilisateur
5. Résoudre les conflits (pas assez de lumière pour les contraintes demandées → proposer des compromis)

#### D. Settings Output (Affichage des résultats)

Chaque réglage est affiché avec **trois niveaux d'information** :

1. **La valeur** — f/2.8, 1/250s, ISO 800
2. **L'explication courte** — "Ouverture grande ouverte pour maximiser l'entrée de lumière et créer du flou d'arrière-plan"
3. **L'explication détaillée** (expandable) — Le raisonnement complet, les compromis, ce qui se passerait si on changeait cette valeur

**Affichage des compromis :**

Quand le moteur fait un compromis (ex : monter les ISO parce que la vitesse minimum est atteinte), il le signale clairement :

> ⚠️ **Compromis** : ISO monté à 3200 pour maintenir 1/500s. Bruit visible possible sur ton A6700 à cet ISO. Alternative : descendre à 1/250s → ISO 1600 (moins de bruit, risque de flou de mouvement).

#### E. Menu Navigation Mapper

**Le killer feature.** Pour chaque réglage recommandé, l'app affiche :

```
📍 Vitesse d'obturation → 1/250s
   Menu > Exposition > Vitesse d'obtu.
   Molette arrière (en mode M)

📍 Mode AF → AF-C
   Menu > AF/MF > Mode mise au point > AF-C (continu)
   Ou : bouton AF-ON > sélecteur de mode
```

- Le chemin est **spécifique au modèle exact** (pas générique par marque)
- Les noms de menus sont **dans la langue configurée** du firmware
- Les **raccourcis physiques** (molettes, boutons) sont mentionnés quand ils existent
- Un **indicateur de profondeur** montre où on en est dans l'arbre (Menu > Sous-menu > Paramètre)

#### F. Offline

- Après le téléchargement initial du data pack, **100% de l'app fonctionne sans réseau**
- Le moteur de calcul tourne en local
- Les données caméra sont stockées localement
- Aucun appel API nécessaire pour le flow principal

### 5.2. V2+ (Post-lancement)

Features priorisées pour les versions futures. **Aucune de ces features n'est nécessaire pour le MVP.**

| Priorité | Feature | Description |
|----------|---------|-------------|
| V2 | Historique & favoris | Sauvegarder ses scènes, retrouver des réglages passés |
| V2 | Mode vidéo avancé | Réglages spécifiques vidéo (framerate, shutter angle, profils couleur, LOG) |
| V2 | Comparaison de réglages | "Et si je passais à f/4 au lieu de f/2.8 ?" — simulation avant/après |
| V2 | Plus de boîtiers | Élargir à 30-50 modèles, gammes plus anciennes |
| V2 | Widget rapide | Accès rapide au dernier réglage ou à un preset sauvegardé |
| V3 | Analyse photo | Upload une photo, l'app lit les EXIF et explique ce qui aurait pu être mieux |
| V3 | Mode apprentissage | Mini-leçons contextuelles liées aux réglages ("Tu veux comprendre l'ouverture ? Voici un cours de 3min") |
| V3 | Communauté | Partage de scènes/réglages entre utilisateurs |
| V3 | AI Scene Assist | Description de scène par texte libre ou photo, interprétée par LLM |
| V4 | Intégration constructeurs | APIs officielles si disponibles un jour |

---

## 6. Contraintes

### 6.1. Contraintes techniques

| Contrainte | Impact |
|-----------|--------|
| **Offline-first obligatoire** | Toute la logique et les données doivent tourner en local après setup initial. Pas de dépendance à un backend pour le flow principal. |
| **Taille des data packs** | Les données d'un boîtier (menus, specs, traductions) doivent rester raisonnables (<5MB par boîtier). L'utilisateur télécharge uniquement son matériel. |
| **Performance mobile** | Le calcul des réglages doit être instantané (<500ms). Pas de loading screen pour le résultat. |
| **Multi-langue menus** | Les arbres de menus doivent exister dans chaque langue supportée par le firmware du boîtier. C'est un effort de data considérable. |
| **Pas de ML/AI dans le MVP** | Le moteur de settings est déterministe (arbres de décision). Prédictible, auditable, pas de "hallucination". L'AI est réservée à V3+. |

### 6.2. Contraintes de données

| Contrainte | Impact |
|-----------|--------|
| **Pas d'API constructeur officielle** | Sony, Canon, Nikon, Fuji ne fournissent pas d'API publique pour leurs arbres de menus. Les données doivent être construites manuellement à partir des manuels PDF officiels. |
| **Mises à jour firmware** | Les menus changent avec les mises à jour firmware. Il faut un système de versioning des data packs. |
| **Exactitude critique** | Un mauvais chemin de menu = perte totale de confiance de l'utilisateur. Les données doivent être vérifiées boîtier en main ou via manuels officiels. |
| **Compatibilité objectif-boîtier** | Les combinaisons possibles sont vastes. Le MVP se concentre sur les objectifs natifs de chaque système de monture. |

### 6.3. Contraintes business

| Contrainte | Impact |
|-----------|--------|
| **Projet personnel / side project** | Développé par une seule personne, budget zéro ou très limité. Pas de team, pas d'investisseurs. |
| **Pas de revenus au lancement** | Modèle économique à définir plus tard (freemium probable : X boîtiers gratuits, premium pour le reste). |
| **Maintenance data** | Chaque nouveau boîtier = effort manuel significatif. Il faut prioriser les boîtiers à forte demande. |

### 6.4. Contraintes légales

| Contrainte | Impact |
|-----------|--------|
| **Données manuels constructeurs** | Les manuels sont protégés par copyright. On extrait des *faits* (noms de menus, structure), pas du contenu éditorial. Les faits ne sont pas protégeables en principe, mais il faut rester prudent. |
| **Noms de marques** | Sony, Canon, Nikon, Fujifilm sont des marques déposées. Usage nominatif autorisé (description de compatibilité), mais pas dans le nom de l'app ni dans un contexte qui suggère un partenariat. |
| **Données personnelles** | Aucune donnée personnelle collectée dans le MVP (pas de compte, pas de tracking). Si historique en V2 → tout en local. |

---

## 7. Hypothèses & Risques

### Hypothèses

1. Les manuels PDF des constructeurs sont suffisamment détaillés pour reconstruire l'arbre de menus complet de chaque boîtier.
2. Les arbres de menus sont relativement stables entre les mises à jour firmware (changements mineurs, pas de refonte).
3. Un système de description de scène structuré (pas de texte libre) suffit à couvrir 90% des situations de shoot réelles.
4. Les débutants préfèrent une recommandation claire avec explication plutôt qu'un outil qui les laisse explorer seuls.
5. 14 boîtiers suffisent pour valider le product-market fit.

### Risques

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| Les données de menus sont trop longues/coûteuses à construire | Moyenne | Critique | Commencer par 2-3 boîtiers, valider le process avant de scaler |
| Le moteur de settings donne de mauvais conseils dans certains edge cases | Haute | Élevé | Arbres de décision bien testés + disclaimer "suggestions, pas garanties" + feedback loop utilisateur |
| Les mises à jour firmware cassent les chemins de menus | Moyenne | Moyen | Versioning des data packs par firmware, système de mise à jour incrémentale |
| Trop de combinaisons scène → réglages impossibles à couvrir | Basse | Moyen | Le système structuré (pas texte libre) limite l'espace des inputs. Fallbacks pour cas non couverts. |
| Concurrents (PhotoPills, etc.) ajoutent cette feature | Basse | Élevé | Avancer vite sur le Menu Navigation Mapper — c'est la barrière à l'entrée |

---

## 8. Métriques de succès (MVP)

On n'a pas de backend analytics au MVP, donc métriques simples et observables :

| Métrique | Cible | Comment mesurer |
|----------|-------|-----------------|
| L'app fonctionne offline | 100% | Test manuel |
| Temps de calcul settings | < 500ms | Profiling |
| Exactitude des chemins de menus | 100% | Vérification manuelle sur les boîtiers supportés |
| Couverture des scénarios de shoot | > 90% des situations courantes | Test avec des photographes débutants |
| Taille data pack par boîtier | < 5MB | Mesure |
| Nombre de boîtiers supportés | 14 au lancement | Count |

---

## 9. Hors périmètre (Explicitement exclu du MVP)

- ❌ Compte utilisateur / authentification
- ❌ Backend applicatif (hors distribution des data packs)
- ❌ Intelligence artificielle / LLM
- ❌ Analyse d'image / lecture EXIF
- ❌ Social / communauté / partage
- ❌ Mode vidéo avancé (profils LOG, LUTs, etc.)
- ❌ Objectifs tiers (Sigma, Tamron, Viltrox) — MVP = objectifs natifs uniquement
- ❌ Boîtiers reflex (MVP = hybrides uniquement)
- ❌ Suggestions de post-traitement
- ❌ Intégration avec Lightroom/Capture One
- ❌ Monétisation

---

## 10. Nom de l'app

**"ShootHelper"** est un nom de travail. Le nom définitif sera choisi plus tard. Critères :

- Court, mémorisable
- Pas de conflit de marque
- Disponible sur App Store + Play Store
- Évoque l'aide au shooting, pas un outil de retouche

---

*Ce document est la référence pour tous les skills suivants. Toute feature ou décision technique doit être traçable à ce PRD.*
