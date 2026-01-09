# SynNiche
Codes for the SynNiche project

## 0. Raw image data

## 1. Microwell Detection and Quantification

### 1.1. Raw Image Acquisition
High-content imaging was performed using the Opera Phenix™ Plus High-Content Screening System (PerkinElmer). Each well was imaged in tile scan mode, covering a 19 × 19 grid (361 fields of view per well) with a 10× air objective. Multichannel fluorescence and brightfield images (brightfield, EGFP, mCherry) were acquired. Image stitching and subsequent processing were conducted using the open-source platform Fiji (ImageJ v1.54p).

### 1.2. Large image stitching
Raw image tiles were initially stitched using the “BIOP Operetta Importer” plugin, which assembled all fields into a single composite image per well while preserving all channels.

### 1.3. Image Pre-processing
Bleed-through correction was applied to reduce EGFP fluorescence spillover into the mCherry channel, particularly important given the strong EGFP and relatively weak mCherry signals. Microwell fluorescence intensity was detected using the “1_macro_for_microwell_quantification_1.ijm” script. Key parameters included BF_channel selection, background channel exclusion (EGFP, mCherry), Hough_threshold = 0.65, Rolling_size = 20, and Threshold_background = 78. The correction coefficient, calculated based on microwells with only EGFP-expressing cells, was used to correct EGFP bleed-through in the mCherry channel.

### 1.4. Bleed-through Correction
The EGFP bleed-through into the mCherry channel was corrected using the “2_bleedthrough.ijm” script. The correction coefficients used are documented in the “image_metadata.xlsx” file.

### 1.5. Hyperstack Alignment
Images from three time points were aligned to establish consistent ROIs for each microwell using “3_hyperstackreg.ijm”. Fluorescence intensities within these ROIs were quantified over time using “4_macro_for_microwell_quantification_2.ijm”.

### 1.6. File Merging
Files were merged according to the EGFP and mCherry channels using “5_Area_mean.R”. Microwells with significant debris (green fluorescence area >3,500) on Day 0 were excluded. A cell expansion score was calculated as the product of area and mean fluorescence value within each ROI for each channel, scaled by 1/10,000,000. Approximately 20% of microwells were classified as empty (expansion score for mCherry on Day 0 < 0.001).

### 1.7. EGFP-based Clustering：
Microwells were grouped into two clusters based on EGFP fluorescence dynamics using “6_Cluster_GFP.R”. Color and transparency keys were applied to visualize the proximity of each data point to the cluster centroid, representing the degree of deviation.

### 1.8. mCherry-based Clustering
Within Group 2 (Cluster B), microwells were further subdivided into three clusters based on mCherry fluorescence dynamics using “7_Cluster_mCherry.R”.

## 2. Protocols for Bulk RNA sequence data analysis

### 2.1. Raw_sequencing data
The raw bulk RNA-seq data (FASTQ files) are publicly available in the ArrayExpress database:

B16-OVA cell expressing transcription factors data: Accession [E-MTAB-15290] (https://www.ebi.ac.uk/biostudies/ArrayExpress/studies/E-MTAB-15356?key=32fe823a-ff57-4cb9-add0-4b75dcfd54ba).

C3H10T1/2 cells expressing transcription factors: Accession [E-MTAB-15356] (https://www.ebi.ac.uk/biostudies/ArrayExpress/studies/E-MTAB-15356?key=32fe823a-ff57-4cb9-add0-4b75dcfd54ba).

### 2.2. Preprocessing of Bulk RNA seq data
