# SynNiche
Codes for the SynNiche project

# Microwell-Rule-Based-Quantification

This repository contains an automated image processing and data analysis pipeline for high-content screening of microwells. The workflow integrates **Fiji (ImageJ)** macros for image stitching, registration, and fluorescence quantification, followed by **R** scripts for data merging, quality control, and time-series clustering.

## Overview

The pipeline is designed to process time-series images (Brightfield, EGFP, mCherry) acquired from the **Opera Phenix™ Plus High-Content Screening System**.

**Key features:**
*   Stitching of tiled scans using the BIOP Operetta Importer plugin.
*   Fluorescence bleed-through correction (EGFP to mCherry).
*   Time-series hyperstack alignment (Image Registration).
*   K-means clustering of cell expansion dynamics.

## Prerequisites

### Software
*   **Fiji (ImageJ)** (v1.54p)
    *   *Download:* https://imagej.net/software/fiji/downloads

### Fiji Dependencies
To ensure all macros run correctly (especially `HyperStackReg` and Stitching), you must enable the following **Update Sites** in Fiji:

1.  Open Fiji.
2.  Go to `Help` > `Update...`
3.  Click `Manage update sites`.
4.  Check the boxes for the following sites:
    *   **BIG-EPFL**
    *   **PTBIOP**
    *   **UCB Vision site**
    *   **ImageScience**
    *   **Bio-Formats**
    *   **IJPB-plugins**
5.  Click `Close` and then `Apply changes`.
6.  Restart Fiji.

*   **Key Plugins used:** [BIOP Operetta Importer](https://github.com/BIOP/ijp-operetta-importer), [HyperStackReg](https://github.com/ved-sharma/HyperStackReg).

---

## Pipeline Workflow

### 1. Raw Image Acquisition & Stitching
**Input:** Raw image tiles (19x19 grid, 10x objective).  
**Tool:** Fiji (BIOP Operetta Importer)

Raw image tiles are stitched using the **BIOP Operetta Importer** plugin. This step assembles all fields of view into a single composite image per well while preserving channel information (Brightfield, EGFP, mCherry).

### 2. Bleed-through Correction
**Goal:** Correct EGFP signal spillover into the mCherry channel.

*   **Step 2a: Intensity Detection**  
    Run script: `1_macro_for_microwell_quantification_1.ijm`  
    This script detects microwells and measures raw fluorescence intensities.
    *   **Key Parameters:**
        *   `Hough_threshold`: 0.65
        *   `Rolling_size`: 20
        *   `Threshold_background`: 78
        *   Background channels excluded: EGFP, mCherry

*   **Step 2b: Correction Application**  
    Run script: `2_bleedthrough.ijm`  
    Based on correction coefficients calculated from EGFP-only controls, this script mathematically subtracts the spillover signal from the mCherry channel.

### 3. Hyperstack Alignment & Quantification
**Goal:** Align time-series images to fix ROI positions and quantify signals over time.

*   **Step 3a: Registration**  
    Run script: `3_hyperstackreg.ijm`  
    Images from three time points (e.g., Day 0, 3, 6) are aligned (registered) to establish consistent ROIs for each microwell across the timeline.

*   **Step 3b: Time-series Quantification**  
    Run script: `4_macro_for_microwell_quantification_2.ijm`  
    Extracts fluorescence intensity and area data from the aligned ROIs.

### 4. Data Processing & Filtering (R)
**Goal:** Merge data, filter debris, and calculate scores.  
Run script: `5_Area_mean.R`

*   **Merging:** Files are merged based on EGFP and mCherry channels.
*   **Debris Filtering:** Microwells with significant debris on Day 0 (Green Area > 3,500) are excluded.
*   **Empty Well Exclusion:** Wells with a Day 0 mCherry score < 0.001 are classified as empty (~20% of wells, consistent with Poisson distribution λ = 1.5).
*   **Scoring:** A "Cell Expansion Score" is calculated as:
    $$ \text{Score} = (\text{Area} \times \text{Mean Intensity}) \times 10^{-6} $$

### 5. Time-Series Clustering
**Goal:** Group microwells based on growth kinetics.

*   **Step 5a: EGFP Clustering**  
    Run script: `6_Cluster_GFP.R`  
    Classifies microwells into **Cluster A** and **Cluster B** (K=2) based on EGFP dynamics. Visualization includes color/transparency gradients representing residual proximity (deviation from centroid).

*   **Step 5b: mCherry Clustering**  
    Run script: `7_Cluster_mCherry.R`  
    Further subdivides Cluster B into **3 sub-clusters** based on mCherry dynamics.

---

## File Structure
*   `macros/`: Contains all .ijm scripts.
*   `R_scripts/`: Contains all .R analysis scripts.

## Usage Note
Please ensure file paths in the scripts are updated to match your local directory structure before running.
