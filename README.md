# 🚗 ENSAssuRances – Analyse des Sinistres Automobiles

> Projet d'ingénierie et d'analyse des données mené au sein de la **Direction Technique Automobile d'ENSAssuRances**, sous la direction du **Prof. Dr. Solym Manou-Abi**.

---

## 📋 Table des matières

- [Contexte](#-contexte)
- [Objectifs](#-objectifs)
- [Structure du projet](#-structure-du-projet)
- [Données](#-données)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Résultats](#-résultats)
- [Livrables](#-livrables)
- [Auteur](#-auteur)
- [Licence](#-licence)

---

## 📌 Contexte

Ce projet porte sur l'analyse de la base de données **Sinistre & Contrat** d'une compagnie fictive d'assurance automobile, **ENSAssuRances**. La base contient **320 000 lignes** et couvre des informations sur les contrats d'assurance et les sinistres associés.

L'analyse vise à étudier la **fréquence**, la **répartition** et les **facteurs de risque** liés aux sinistres automobiles, afin de produire des insights exploitables pour la gestion des risques assurantiels.

---

## 🎯 Objectifs

- ✅ Structurer, nettoyer et transformer la base de données sinistres et contrats
- ✅ Produire des analyses exploratoires et statistiques détaillées
- ✅ Visualiser les données pour faciliter la prise de décision
- ✅ Identifier les caractéristiques des contrats et véhicules à risque
- ✅ Documenter et diffuser le travail avec des outils professionnels (GitHub, RMarkdown, RPubs)

---

## 📁 Structure du projet

```
ENSAssuRances/
│
├── 📂 data/                        # Données brutes (non versionnées)
│   ├── Contrat.xlsx                # 301 437 lignes × 40 colonnes
│   └── Sinistre.xlsx               # 72 130 lignes × 8 colonnes
│
├── 📂 docs/
|   ├── Dico-Contrat-Sinistre-2.pdf
|   └── Dico-données-1.pdf
|
├── 📂 scripts/                     # Scripts R
│   └── ENSAssuRances_Patxi_Bidart.R
│
├── 📂 py/                     # Scripts R
│   └── Devoir_ENSAssuRances_Patxi_Bidart.py
│
├── 📂 reports/                      # Rapport RMarkdown
|   ├── ENSAssuRances_Patxi_Bidart.Rmd 
│   └── ENSAssuRances_Patxi_Bidart.html                     
│
├── .gitignore
└── README.md
```

---

## 🗃️ Données

Les fichiers de données ne sont pas inclus dans ce dépôt en raison de leur taille (> 25 MB).

📥 **Télécharger les données ici :**

| Fichier | Description | Lien |
|---|---|---|
| `Contrat.xlsx` | 301 437 contrats d'assurance automobile | [Kaggle 🔗](https://www.kaggle.com/datasets/patxibidart/ensassurances-sinistres-et-contrats-automobiles?select=Sinistre.xlsx) |
| `Sinistre.xlsx` | 72 130 sinistres déclarés | [Kaggle 🔗](https://www.kaggle.com/datasets/patxibidart/ensassurances-sinistres-et-contrats-automobiles?select=Sinistre.xlsx) |

---

## ⚙️ Installation

### Prérequis

- R ≥ 4.1.0
- RStudio ≥ 2022.07

### Packages R requis

```r
install.packages(c(
  "readxl", "dplyr", "tidyr", "ggplot2",
  "lubridate", "scales", "stringr", "naniar",
  "sf", "leaflet", "RColorBrewer", "knitr", "rmarkdown"
))
```

## 🚀 Utilisation

### Exécuter le script R

Ouvrir `scripts/ENSAssuRances_Patxi_Bidart.R` dans RStudio et exécuter l'intégralité du script.

### Générer le rapport HTML

```r
rmarkdown::render("report/ENSAssuRances_Patxi_Bidart.Rmd")
```

Ou dans RStudio : ouvrir le `.Rmd` et cliquer sur **Knit → Knit to HTML**.

---

## 📊 Résultats

### Volet 1 – Ingénierie des données

| Étape | Description |
|---|---|
| 4.1 Manipulation | Nettoyage, filtrage, groupby, création de variables |
| 4.2 Recodage | Recodage catégoriel, normalisation, agrégation |
| 4.3 Jointures | LEFT / RIGHT / INNER JOIN entre Contrat et Sinistre |
| 4.4 Contrôle | Boucles, fonctions, score de risque |
| 4.5 Exploration | Distributions, dates, proportions |
| 4.6 Valeurs manquantes | Imputation médiane / "Inconnu", visualisation |
| 4.7 Données spécifiques | Zones géographiques, segments, options contractuelles |

### Volet 2 – Visualisations produites

- 📈 Évolution des sinistres et contrats par année
- 🚘 Répartition des types et groupes de véhicules
- 👤 Sinistralité selon l'âge, le sexe, le kilométrage
- 🏆 Top 10 des segments à risque élevé
- 🗺️ Carte choroplèthe interactive des départements à risque

### Principaux insights

- Les **jeunes conducteurs** (< 25 ans) et les **véhicules puissants** (> 150 DIN) concentrent les scores de risque les plus élevés
- Une **disparité géographique** significative est observée entre les départements
- Les **petits rouleurs** déclarent légèrement moins de sinistres (0.389 vs 0.397), confirmant l'intérêt de l'option kilométrique
- La variable `ctAssBase` ne présente qu'une seule modalité et ne permet pas de discrimination du risque

---

## 📦 Livrables

| Livrable | Lien |
|---|---|
| 📊 Dataset (Kaggle) | [Voir le dataset 🔗](https://www.kaggle.com/datasets/patxibidart/ensassurances-sinistres-et-contrats-automobiles?select=Sinistre.xlsx) |
| 💻 Code source (GitHub) | Ce dépôt |

---

## 👤 Auteur

**Patxi Bidart**
Projet réalisé dans le cadre du cours d'ingénierie des données
Encadrant : **Prof. Dr. Solym Manou-Abi**

---

## 📄 Licence

- **Code** : [MIT License](LICENSE)
