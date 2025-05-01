# Data Folder
This folder contains data and processed outputs used in the microbial community analysis pipeline, including metadata, sequence information, and intermediate results from DADA2 through ordination analyses.

## Files and Folders
### Files
- `metadata.csv`: Sample metadata file (e.g., Run, brand (i.e., A, B, C), Inoculum (i.e., Ctrl, Ecoli, Lm), sample ID, Sampling_point (i.e., UBD, UBD5), season_environment (i.e., Early (Fall), Late (Spring))) used for mapping and statistical comparisons.
- `ena-file-download-read_run-PRJNA792031.txt`: File containing links to sequencing read accessions (from the ENA for PRJNA792031).

### Folders
- `01_DADA2/`: Contains outputs from the DADA2 pipeline, such as filtered reads, ASV tables, chimera removal, and summary stats.
- `03_PreProcessing/`: Includes preliminary filtering steps applied to the ASV table prior to downstream analyses.
- `04_PhylogeneticTree/`: Outputs from phylogenetic tree construction (e.g., multiple sequence alignment, tree building with FastTree).
- `06_Ordination/`: Contains scaled_physeq.RData object.
