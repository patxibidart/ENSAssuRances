# =============================================================
# Analyse des sinistres automobiles chez ENSAssuRances
# =============================================================

# =========================
# IMPORTATION DES PACKAGES
# =========================

# Installation et appel des packages nécessaires pour cette étude

library(readxl)      # Lecture fichiers Excel 
library(dplyr)       # Manipulation données tabulaires
library(tidyr)       # Reshape / pivot 
library(ggplot2)     # Visualisations
library(lubridate)   # Gestion des dates
library(scales)      # Formatage des axes
library(stringr)     # Manipulation de chaînes
library(naniar)      # Visualisation valeurs manquantes
library(sf)          # Données spatiales
library(leaflet)     # Carte interactive
library(RColorBrewer) # Palettes de couleurs

# =========================
# IMPORTATION DES DONNÉES
# =========================

contrat  <- read_excel("Contrat.xlsx")
sinistre <- read_excel("Sinistre.xlsx")

# Affichage des dimensions des deux datasets
cat("Contrat shape :", nrow(contrat), "lignes x", ncol(contrat), "colonnes\n")
cat("Sinistre shape :", nrow(sinistre), "lignes x", ncol(sinistre), "colonnes\n")

# Aperçu des données
cat("\n", strrep("=", 50), "\n")
cat("📊 APERÇU DU DATASET CONTRAT\n")
cat(strrep("=", 50), "\n")
print(head(contrat))

cat("\n", strrep("=", 50), "\n")
cat("📊 APERÇU DU DATASET SINISTRE\n")
cat(strrep("=", 50), "\n")
print(head(sinistre))

# Informations sur les types et NA
cat("\n", strrep("=", 50), "\n")
cat("📌 INFORMATIONS - CONTRAT\n")
cat(strrep("=", 50), "\n")
str(contrat)
cat("Valeurs manquantes par colonne :\n")
print(colSums(is.na(contrat)))

cat("\n", strrep("=", 50), "\n")
cat("📌 INFORMATIONS - SINISTRE\n")
cat(strrep("=", 50), "\n")
str(sinistre)
cat("Valeurs manquantes par colonne :\n")
print(colSums(is.na(sinistre)))

# ====================================
# 4.1 MANIPULATION DE DONNÉES TABULAIRES
# ====================================

# A. Nettoyage des données

# Détection des doublons
cat("Doublons CONTRAT :", sum(duplicated(contrat)), "\n")
cat("Doublons SINISTRE :", sum(duplicated(sinistre)), "\n")

# Suppression des doublons
contrat  <- distinct(contrat)
sinistre <- distinct(sinistre)

# Conversion explicite de toutes les colonnes numériques clés
contrat <- contrat %>%
  mutate(
    drv1Age   = as.numeric(drv1Age),
    vhAge     = as.numeric(vhAge),
    vhDIN     = as.numeric(vhDIN),
    vhValue   = as.numeric(vhValue),
    claimsAnt = as.numeric(claimsAnt),
    vhGroup   = as.numeric(vhGroup),
    idxYear   = as.numeric(idxYear)
  )

# B. Détection des incohérences

# Âge conducteur < 18 ou > 100
inco_age <- contrat %>% filter(drv1Age < 18 | drv1Age > 100)
cat("Ages incohérents :", nrow(inco_age), "\n")

# Âge véhicule négatif
inco_vh <- contrat %>% filter(vhAge < 0)
cat("Age véhicule incohérent :", nrow(inco_vh), "\n")

# C. Filtrage
# Garder uniquement les contrats valides (conducteurs >= 18 ans)
contrat_clean <- contrat %>% filter(drv1Age >= 18)

# Véhicules électriques
veh_elec <- contrat %>% filter(vhEnergy == "Electric")

# D. Groupby + summarise
# Nombre de contrats par année
contrats_par_an <- contrat %>%
  group_by(idxYear) %>%
  summarise(nb_contrats = n(), .groups = "drop")

# Moyenne d'âge du conducteur par année
age_moyen <- contrat %>%
  group_by(idxYear) %>%
  summarise(drv1Age = mean(drv1Age, na.rm = TRUE), .groups = "drop")

print(head(contrats_par_an))
print(head(age_moyen))

# E. Order by / tri
contrats_par_an <- contrats_par_an %>%
  arrange(desc(nb_contrats))
print(contrats_par_an)

# F. Création de variables (classe d'âge, jeune conducteur)
# Classe d'âge
# Conversion explicite en numérique avant le cut
contrat <- contrat %>%
  mutate(
    drv1Age = as.numeric(drv1Age),  # conversion
    classe_age = cut(
      drv1Age,
      breaks = c(18, 25, 40, 60, 100),
      labels = c("18-25", "25-40", "40-60", "60+"),
      include.lowest = TRUE
    ),
    jeune_conducteur = as.integer(drv1Age < 25)
  )

# G. Sous-ensembles
# Jeunes conducteurs
jeunes <- contrat %>% filter(jeune_conducteur == 1)

# Véhicules puissants (> 150 DIN)
puissants <- contrat %>% filter(vhDIN > 150)

# ====================================
# 4.2 RECODAGE ET TRANSFORMATION
# ====================================

# A. Recodage des variables catégorielles

# Sexe : H -> Homme, F -> Femme
contrat <- contrat %>%
  mutate(drv1Sex = recode(drv1Sex,
    "H" = "Homme",
    "F" = "Femme"
  ))

# Énergie du véhicule
contrat <- contrat %>%
  mutate(vhEnergy = recode(vhEnergy,
    "G" = "Essence",
    "D" = "Diesel",
    "E" = "Electrique"
  ))

# B. Transformation de variables continues
# Normalisation de l'âge
contrat <- contrat %>%
  mutate(drv1Age_norm = (drv1Age - mean(drv1Age, na.rm = TRUE)) /
                         sd(drv1Age, na.rm = TRUE))

# C. Agrégation

# Extraction de l'année depuis la date de déclaration
sinistre <- sinistre %>%
  mutate(
    decl_sin = as.Date(decl_sin),
    annee    = year(decl_sin)
  )

# Nombre de sinistres par année
sinistres_par_an <- sinistre %>%
  group_by(annee) %>%
  summarise(nb_sinistres = n(), .groups = "drop")

# Statistiques par type de véhicule
vehicule_stats <- contrat %>%
  group_by(vhSegment) %>%
  summarise(
    age_moyen    = mean(drv1Age, na.rm = TRUE),
    valeur_moy   = mean(vhValue, na.rm = TRUE),
    .groups = "drop"
  )

# Nombre de contrats par zone géographique
zone_stats <- contrat %>%
  group_by(ctINSEE) %>%
  summarise(nb_contrats = n(), .groups = "drop")

# Distribution de l'âge
ggplot(contrat, aes(x = drv1Age)) +
  geom_histogram(fill = "steelblue", color = "white", bins = 30) +
  labs(title = "Distribution de l'âge du conducteur", x = "Âge", y = "Effectif") +
  theme_minimal()

# ====================================
# 4.3 JOINTURE DE DONNÉES
# ====================================

# Il n'y a pas de clé commune aux deux datasets.
# On regroupe les IDs sinistres référencés dans les contrats pour créer la liaison.

# Colonnes des IDs sinistres dans le dataset contrat
cols_sin <- c(
  "id1_AssBase", "id2_AssBase", "id3_AssBase",
  "id1_Ass0km",  "id2_Ass0km",  "id3_Ass0km",
  "id1_AssVHR",  "id2_AssVHR",  "id3_AssVHR"
)

# Sélection des colonnes utiles
contrat_sin <- contrat %>% select(idxCt, all_of(cols_sin))

# Passage en format long
contrat_sin_long <- contrat_sin %>%
  pivot_longer(
    cols      = all_of(cols_sin),
    names_to  = "variable",
    values_to = "idx_sin"
  ) %>%
  filter(!is.na(idx_sin))   # Suppression des NA

# ---------- LEFT JOIN ----------
# Tous les liens contrat-sinistre, même si le sinistre n'est pas retrouvé
df_left <- contrat_sin_long %>%
  left_join(sinistre, by = "idx_sin")

cat("LEFT JOIN\n")
cat("Nb lignes :", nrow(df_left), "\n")
cat("NA sinistre :", sum(is.na(df_left$gar_sin)), "\n")
print(head(df_left))

# ---------- RIGHT JOIN ----------
# Tous les sinistres, même sans contrat associé
df_right <- contrat_sin_long %>%
  right_join(sinistre, by = "idx_sin")

cat("RIGHT JOIN\n")
cat("Nb lignes :", nrow(df_right), "\n")
cat("NA sinistre :", sum(is.na(df_right$gar_sin)), "\n")
print(head(df_right))

# ---------- INNER JOIN ----------
# Uniquement les correspondances exactes entre contrat et sinistre
df_inner <- contrat_sin_long %>%
  inner_join(sinistre, by = "idx_sin")

cat("INNER JOIN\n")
cat("Nb lignes :", nrow(df_inner), "\n")
cat("NA sinistre :", sum(is.na(df_inner$gar_sin)), "\n")
print(head(df_inner))

# Taux de perte (sinistres non retrouvés)
taux_perte <- mean(is.na(df_left$gar_sin)) * 100

cat(strrep("=", 50), "\n")
cat("📊 COMPARAISON DES JOINTURES\n")
cat(strrep("=", 50), "\n")
cat("LEFT JOIN garde tous les liens contrat-sinistre\n")
cat("INNER JOIN supprime les sinistres non retrouvés\n")
cat("Différence de lignes :", nrow(df_left) - nrow(df_inner), "\n")
cat("Taux de sinistres non retrouvés :", round(taux_perte, 2), "%\n")

# Nombre de sinistres par contrat
nb_sinistres <- df_inner %>%
  group_by(idxCt) %>%
  summarise(n_sinistres = n(), .groups = "drop")

print(summary(nb_sinistres$n_sinistres))

# Visualisation de la distribution
ggplot(nb_sinistres, aes(x = n_sinistres)) +
  geom_histogram(fill = "steelblue", color = "white", bins = 20) +
  labs(
    title = "Distribution du nombre de contrat par nombre de sinistres antérieurs",
    x = "Nombre de sinistres",
    y = "Fréquence"
  ) +
  theme_minimal()

# ====================================
# 4.4 CONTRÔLE ET FLUX DE DONNÉES
# ====================================

# Structures conditionnelles et boucles

# Fonction IF/ELSE : catégorie d'âge
categorie_age <- function(age) {
  if (age < 25) {
    return("Jeune")
  } else if (age < 60) {
    return("Adulte")
  } else {
    return("Senior")
  }
}

# Application avec sapply
contrat <- contrat %>%
  mutate(categorie_age = sapply(drv1Age, categorie_age))

# Boucle FOR : calcul de la moyenne d'âge par segment
segments <- unique(contrat$vhSegment)

for (seg in segments) {
  moyenne <- mean(contrat$drv1Age[contrat$vhSegment == seg], na.rm = TRUE)
  cat(sprintf("Segment %s -> âge moyen : %.2f\n", seg, moyenne))
}

# Fonction apply : calcul d'un score de risque
score_risque <- function(row) {
  score <- 0
  if (!is.na(row["drv1Age"])  && as.numeric(row["drv1Age"])  < 25) score <- score + 2
  if (!is.na(row["vhDIN"])    && as.numeric(row["vhDIN"])    > 150) score <- score + 2
  if (!is.na(row["claimsAnt"])&& as.numeric(row["claimsAnt"]) > 0)  score <- score + 3
  return(score)
}

# Application ligne par ligne
contrat <- contrat %>%
  mutate(
    score_risque = case_when(
      drv1Age < 25 & vhDIN > 150 & claimsAnt > 0 ~ 7,
      drv1Age < 25 & vhDIN > 150                  ~ 4,
      drv1Age < 25 & claimsAnt > 0                ~ 5,
      vhDIN > 150  & claimsAnt > 0                ~ 5,
      drv1Age < 25                                 ~ 2,
      vhDIN > 150                                  ~ 2,
      claimsAnt > 0                                ~ 3,
      TRUE                                         ~ 0
    )
  )

# TOP 10 scores de risque
top10 <- contrat %>%
  arrange(desc(score_risque)) %>%
  select(idxCt, drv1Age, vhDIN, claimsAnt, score_risque) %>%
  head(10)

print(top10)

# Histogramme des scores de risque
ggplot(contrat, aes(x = score_risque)) +
  geom_histogram(fill = "steelblue", color = "white", bins = 10) +
  labs(
    title = "Distribution du score de risque",
    x     = "Score",
    y     = "Fréquence"
  ) +
  theme_minimal()

# Recherche de cas spécifiques
veh_elec      <- contrat %>% filter(vhEnergy == "Electrique")
jeunes        <- contrat %>% filter(drv1Age < 25)
petits_rouleurs <- contrat %>% filter(ctKM == "Petit")

# ====================================
# 4.5 TRANSFORMATION ET EXPLORATION
# ====================================

# Distribution de l'âge
ggplot(contrat, aes(x = drv1Age)) +
  geom_histogram(fill = "steelblue", color = "white", bins = 30) +
  labs(title = "Distribution de l'âge", x = "Âge", y = "Effectif") +
  theme_minimal()

# Distribution des sinistres antérieurs
ggplot(contrat, aes(x = claimsAnt)) +
  geom_histogram(fill = "coral", color = "white", bins = 20) +
  labs(title = "Distribution des sinistres antérieurs",
       x = "Nombre de sinistres", y = "Effectif") +
  theme_minimal()

# Répartition des types de véhicules
ggplot(contrat, aes(x = vhSegment)) +
  geom_bar(fill = "orange") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Répartition des types de véhicules",
       x = "Type de véhicule", y = "Nombre") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Gestion des dates
contrat <- contrat %>%
  mutate(
    sitStartDate  = as.Date(sitStartDate),
    annee_contrat = year(sitStartDate)
  )

sinistre <- sinistre %>%
  mutate(annee_sinistre = year(decl_sin))

# Proportions par sexe
prop_sexe <- contrat %>%
  count(drv1Sex) %>%
  mutate(pourcentage = n / sum(n) * 100)

print(prop_sexe)

ggplot(prop_sexe, aes(x = drv1Sex, y = pourcentage)) +
  geom_col(fill = "steelblue") +
  labs(title = "Répartition du sexe (%)", x = "Sexe", y = "Pourcentage") +
  theme_minimal()

# ====================================
# 4.6 VALEURS MANQUANTES ET DATA PROCESSING
# ====================================

# Identification des valeurs manquantes par variable
na_contrat  <- colSums(is.na(contrat))  %>% sort(decreasing = TRUE)
na_sinistre <- colSums(is.na(sinistre)) %>% sort(decreasing = TRUE)

print(na_contrat)
print(na_sinistre)

# Stratégies d'imputation
# Numérique -> médiane
contrat <- contrat %>%
  mutate(drv1Age = if_else(is.na(drv1Age), median(drv1Age, na.rm = TRUE), drv1Age))

# Catégoriel -> "Inconnu"
contrat <- contrat %>%
  mutate(vhEnergy = if_else(is.na(vhEnergy), "Inconnu", vhEnergy))

# Visualisation des valeurs manquantes

# Calcul du % de NA par colonne
na_pct <- contrat %>%
  summarise(across(everything(), ~ mean(is.na(.)) * 100)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "pct_na") %>%
  filter(pct_na > 0) %>%          # Garder uniquement les colonnes avec des NA
  arrange(desc(pct_na))

# Graphique
ggplot(na_pct, aes(x = reorder(variable, pct_na), y = pct_na)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Pourcentage de valeurs manquantes par variable",
    x     = "Variable",
    y     = "% de NA"
  ) +
  theme_minimal()

# Fonction de nettoyage reproductible
clean_data <- function(df) {
  df <- distinct(df)  # Suppression des doublons
  df <- df %>%
    mutate(
      drv1Age   = if_else(is.na(drv1Age), median(drv1Age, na.rm = TRUE), drv1Age),
      vhEnergy  = if_else(is.na(vhEnergy), "Inconnu", vhEnergy)
    )
  return(df)
}

contrat <- clean_data(contrat)

# ====================================
# 4.7 DONNÉES SPÉCIFIQUES
# ====================================

# Analyse spatiale : zones à risque par code INSEE
zone_risque <- contrat %>%
  group_by(ctINSEE) %>%
  summarise(risque_moyen = mean(claimsAnt, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(risque_moyen))

cat("Top 10 zones les plus risquées :\n")
print(head(zone_risque, 10))

# Risque par type de véhicule
risque_segment <- contrat %>%
  group_by(vhSegment) %>%
  summarise(risque_moyen = mean(claimsAnt, na.rm = TRUE), .groups = "drop")

# Risque par groupe de véhicule
risque_groupe <- contrat %>%
  group_by(vhGroup) %>%
  summarise(risque_moyen = mean(claimsAnt, na.rm = TRUE), .groups = "drop")

# Risque par sexe
risque_sexe <- contrat %>%
  group_by(drv1Sex) %>%
  summarise(risque_moyen = mean(claimsAnt, na.rm = TRUE), .groups = "drop")

print(risque_segment)
print(head(risque_groupe))
print(risque_sexe)

# Analyse selon option kilométrique et assurance de base
risque_km <- contrat %>%
  group_by(ctKM) %>%
  summarise(risque_moyen = mean(claimsAnt, na.rm = TRUE), .groups = "drop")

# Une seule modalité 
risque_assurance <- contrat %>%
  group_by(ctAssBase) %>%
  summarise(risque_moyen = mean(claimsAnt, na.rm = TRUE), .groups = "drop")

print(risque_km)
print(risque_assurance)

# =============================================================
# 5. VOLET 2 – ANALYSE ET VISUALISATION (ggplot2)
# =============================================================

# ---- Histogramme du nombre de sinistres par année ----
sin_par_an <- sinistre %>%
  group_by(annee) %>%
  summarise(nb_sinistres = n(), .groups = "drop")

ggplot(sin_par_an, aes(x = annee, y = nb_sinistres)) +
  geom_col(fill = "steelblue") +
  scale_x_continuous(breaks = unique(sin_par_an$annee)) +
  labs(
    title = "Nombre de sinistres par année",
    x     = "Année",
    y     = "Nombre de sinistres"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ---- Distribution des contrats par année ----
ggplot(contrat, aes(x = annee_contrat)) +
  geom_bar(fill = "darkgreen") +
  scale_x_continuous(breaks = sort(unique(contrat$annee_contrat))) +
  labs(
    title = "Distribution des contrats par année",
    x     = "Année",
    y     = "Nombre de contrats"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ---- Bar plot répartition types de véhicules ----
ggplot(contrat, aes(x = vhSegment)) +
  geom_bar(fill = "orange") +
  labs(
    title = "Répartition des types de véhicules",
    x     = "Type de véhicule",
    y     = "Nombre"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ---- Répartition selon l'alimentation ----
ggplot(contrat, aes(x = vhEnergy)) +
  geom_bar(fill = "purple") +
  labs(
    title = "Répartition des énergies",
    x     = "Énergie",
    y     = "Nombre"
  ) +
  theme_minimal()

# ---- Distribution par groupe de véhicule ----
ggplot(contrat, aes(x = vhGroup)) +
  geom_histogram(bins = 20, fill = "skyblue", color = "white") +
  labs(
    title = "Distribution des groupes de véhicules",
    x     = "Groupe",
    y     = "Fréquence"
  ) +
  theme_minimal()

# ---- Histogramme option petit rouleur ----
ggplot(contrat, aes(x = ctKM)) +
  geom_bar(fill = "red") +
  labs(
    title = "Contrats selon option kilométrage",
    x     = "Type (petit rouleur ou non)",
    y     = "Nombre"
  ) +
  theme_minimal()

# ---- Sinistres en fonction de l'âge ----
ggplot(contrat, aes(x = drv1Age, y = claimsAnt)) +
  geom_point(alpha = 0.3) +
  labs(
    title = "Sinistres en fonction de l'âge",
    x     = "Âge",
    y     = "Nombre de sinistres"
  ) +
  theme_minimal()

# ---- Distribution des sinistres antérieurs ----
ggplot(contrat, aes(x = claimsAnt)) +
  geom_histogram(bins = 15, fill = "darkblue", color = "white") +
  labs(
    title = "Distribution des sinistres antérieurs",
    x     = "Nombre de sinistres",
    y     = "Fréquence"
  ) +
  theme_minimal()

# ---- Risque moyen par segment ----
risque_segment <- contrat %>%
  group_by(vhSegment) %>%
  summarise(claimsAnt = mean(claimsAnt, na.rm = TRUE), .groups = "drop")

ggplot(risque_segment, aes(x = vhSegment, y = claimsAnt)) +
  geom_col(fill = "darkred") +
  labs(
    title = "Risque moyen par type de véhicule",
    x     = "Segment",
    y     = "Nombre moyen de sinistres"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ---- Top 10 véhicules les plus risqués ----
top_risque <- risque_segment %>%
  arrange(desc(claimsAnt)) %>%
  head(10)

ggplot(top_risque, aes(x = reorder(vhSegment, claimsAnt), y = claimsAnt)) +
  geom_col(fill = "black") +
  coord_flip() +
  labs(
    title = "Top 10 des véhicules les plus risqués",
    x     = "Segment",
    y     = "Risque"
  ) +
  theme_minimal()

# ============================
# SINISTRES PAR SEXE
# ============================

sin_sexe <- contrat %>%
  group_by(drv1Sex) %>%
  summarise(claimsAnt = sum(claimsAnt, na.rm = TRUE), .groups = "drop") %>%
  mutate(pourcentage = claimsAnt / sum(claimsAnt) * 100)

print(sin_sexe)

# Nombre de sinistres par sexe
ggplot(sin_sexe, aes(x = drv1Sex, y = claimsAnt)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = scales::comma(claimsAnt)), vjust = -0.5) +
  labs(
    title = "Nombre total de sinistres selon le sexe",
    x     = "Sexe",
    y     = "Nombre de sinistres"
  ) +
  theme_minimal()

# Pourcentage de sinistres par sexe
ggplot(sin_sexe, aes(x = drv1Sex, y = pourcentage)) +
  geom_col(fill = "darkgreen") +
  geom_text(aes(label = sprintf("%.1f%%", pourcentage)), vjust = -0.5) +
  labs(
    title = "Pourcentage de sinistres selon le sexe",
    x     = "Sexe",
    y     = "Pourcentage (%)"
  ) +
  theme_minimal()

# ============================
# CARTE DES ZONES À RISQUE
# ============================

# Extraction du code département (2 premiers caractères du code INSEE)
contrat <- contrat %>%
  mutate(
    departement = str_sub(as.character(ctINSEE), 1, 2),
    # Correction Corse : "20" -> "2A" (simplification)
    departement = if_else(departement == "20", "2A", departement)
  )

# Calcul du risque moyen par département
risque_dep <- contrat %>%
  group_by(departement) %>%
  summarise(risque = mean(claimsAnt, na.rm = TRUE), .groups = "drop") %>%
  rename(code = departement)

# Chargement du GeoJSON France
# Utilisation du package sf pour lire le GeoJSON directement depuis GitHub
url_geojson <- "https://raw.githubusercontent.com/gregoiredavid/france-geojson/master/departements.geojson"

# Chargement du GeoJSON
departements_sf <- sf::st_read(url_geojson, quiet = TRUE)

# Jointure avec les données de risque
carte_data <- departements_sf %>%
  left_join(risque_dep, by = "code")

# Palette de couleurs
pal <- colorNumeric("Reds", domain = carte_data$risque, na.color = "grey")

# Carte
leaflet(carte_data) %>%
  addTiles() %>%
  addPolygons(
    fillColor   = ~pal(risque),
    fillOpacity = 0.8,
    color       = "white",
    weight      = 1,
    label       = ~paste0(nom, " : ", round(risque, 3))
  ) %>%
  addLegend(
    pal      = pal,
    values   = ~risque,
    title    = "Risque moyen",
    position = "bottomright"
  ) %>%
  setView(lng = 2.5, lat = 46.5, zoom = 5)

