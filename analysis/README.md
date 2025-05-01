# Analysis Folder
This folder contains the R Markdown (.Rmd) source files and corresponding rendered HTML reports for each stage of the microbial community analysis pipeline for this project.

## File Structure

Each step includes:

- The `.Rmd` file: editable analysis script
- The `.html` file: rendered output for viewing results

## Steps

### `01_QualityTrimming`
#### Goals of this file 

1. Use raw fastq files and generate quality plots to assess quality of reads.
2. Filter and trim out bad sequences and bases from our sequencing files. 
3. Write out fastq files with high quality sequences. 
4. Evaluate the quality from our filter and trim. 
5. Infer Errors on forward and reverse reads individually.
6. Identified ASVs on forward and reverse reads separately, using the error model.  
7. Merge forward and reverse ASVs into "contiguous ASVs".  
8. Generate the ASV count table. (`otu_table` input for phyloseq.). 


#### Output that we will create in this file: 

1. Quality plots to asses pre- and post-quality trimming. 
2. Written files that include the filtered and trimmed data. (Note that this will be written during the `filterAndTrim()` function.)

### `02_AssignASVs`
#### Goals 

1. Infer an error model for in the filtered sequences, separately on forward and reverse reads.
2. Assign ASVs on both forward and reverse reads separately by applying the error model.
3. Merge forward and reverse ASVs into "contiguous ASVs".
4. Generate the first draft of ASV count table.
5. Quality Trimming of ASV lengths.
6. Remove chimeras. 
7. Assign Taxonomy with Silva Database. 
8. Write out relevant files: `asv_table`, `asvs_fasta`, `tax_table`, and `sample_data`.

#### Input 

1. Filtered fastq files generated from `01_QualityTrimming.Rmd`.
2. Sample Name vector.

#### Output 

1. ASV Count Table: `asv_table` (with and without sequence names)
2. ASV fasta file: `asvs_fasta` for building a phylogenetic tree at a later step.
3. Taxonomy Table  `tax_table`
4. Sample Information: `sample_data`  track the reads lots throughout DADA2 workflow. 

### `03_PreProcessing`
#### Goals 

First, we will use the [phyloseq package](https://joey711.github.io/phyloseq/) to combine all of our data objects that we exported from the DADA2 workflow (`asv_table`, `tax_table`, and metadata) and incorporate them into a single [specialized S4 R Data object](https://adv-r.hadley.nz/s4.html), known as a phyloseq object. Then, we will remove any potential contaminants and evaluate the accuracy of our sequencing run. Finally, we will write our single `raw_preprocessed_physeq` phyloseq data object. 

#### Specific Steps: 

1. Load in data that we've generated in `analysis/02_AssignASVs.Rmd` and fix all of the names to match each other. *The names must match for us to incorporate them into the S4 phyloseq object*: 
    a. `asv_table`: ASVs (rows) x Samples (columns)
    b. `tax_table`: ASV (rows) x Taxonomy (columns)
    c. `metadata`: Samples (rows) x All our data (*e.g. pH, Temp, treatment group, etc*; columns)
2. Combine the data into a phyloseq object. 
3. Remove any contaminating ASVs that are **chloroplasts**. 
4. Remove ASVs that are **mitochondria**. 
5. Evaluate any ASVs from the **negative controls**. Then, remove negative controls. 
6. Evaluate the mock community or **positive control** to learn the accuracy of sequencing. 
7. Check for **reverse complements**. 
8. Check the **sequencing depth** of samples. Remove samples that obviously have too few reads. 
9. Write a `raw_preprocessed_physeq` to be used in the next step of our workflow. 

#### Input 

1. **Metadata**: `metadata.csv` and `data/01_DADA2/track_read_counts.RData`.
2. **ASV table**: `data/01_DADA2/ASV_table.csv` 
3. **Taxonomy Table**: `data/01_DADA2/ASV_taxonomy.tsv`

#### Output 

1. A **pre-processed S4 phyloseq object**: `raw_preprocessed_physeq.RData`.

### `04A_Phylogenetic_Tree_Construction`
#### Goals 

The goal of this script is to make a phylogenetic tree so we can use it for phylogenetic community analyses like phylogenetic Hill Numbers and the UniFrac beta-diversity measures. 

1. Load in pre-processed phyloseq object. 
2. Create ASV fasta file from the phyloseq object.
3. Align the 16S Sequences from our fasta file using the software [MAFFT](https://academic.oup.com/mbe/article/30/4/772/1073398).  
4. Create a maximum likelihood tree using the software [FastTree2](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0009490). 
5. Write out the tree file for use in the next step of the analyses. 

#### Inputs 
1. Our previously pre-processed phyloseq object that has chloroplasts, mitochondria, reverse complements, and negative controls removed, which is located in `data/03_PreProcessing/raw_preprocessed_physeq`

#### Outputs 
1. The **aligned 16S rRNA gene sequences**, which is the input to the phylogenetic tree. We will save our alignment to `data/04_PhylogeneticTree/MAAFT_aligned_ASV.fasta`
2. The **calculated phylogenetic tree file**, which is the input to the phylogenetic tree. We will save our alignment to`data/04_PhylogeneticTree/ASVs_unrooted.tree`

### `04B_Phylogenetic_Tree_Inspection`

#### Goals 

1. Load the [FastTree2](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0009490) unrooted tree that we calculated in `analysis/04A_Phylogenetic_Tree_Construction.Rmd` and `raw_preprocessed_physeq``.  
2. Merge the unrooted tree to the `raw_preprocessed_phyloseq` object.  
3. Visualize and inspect tree with [ggtree](https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/2041-210X.12628).
4. Evaluate long branches & prune ASVs, if needed. *If your dataset has long branches, you will need to do this before rooting!!*
5. After pruning, root the tree, ideally within the Archaea and, if not, mid-root the tree.
6. Combine the new, rooted tree with the phyloseq object. 
7. Save 2 phyloseq objects: 1. Unrooted tree phyloseq object, 2. Rooted tree phyloseq object. 

#### Inputs 

1. Our previously pre-processed phyloseq object that has chloroplasts, mitochondria, reverse complements, and negative controls removed, which is located in `data/03_PreProcessing/raw_preprocessed_physeq`.
2. The raw, unrooted maximum likelihood tree that we generated using  [FastTree2](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0009490), which is located in `data/04_PhylogeneticTree/ASVs_unrooted.tree`

#### Outputs 

1. The output of this file will be a S4 phloseq objected called `phytree_preprocessed_physeq`, which we will save to `data/04_PhylogeneticTree/`. 

### `05_Biodiversity.Rmd`
#### Goals 

Run an analysis on the within-sample biodiversity of the samples in our project. 

1. Calculate the Hill Numbers of the samples using the iNEXT package. 
2. Plot and evaluate the interpolated and extrapolated rarefaction curves from iNEXT. 
3. Analyze the Hill numbers as it relates to stations and salinity (in PSU).
4. Test and then answer the scientific question at hand! (Remember, we're doing biology!)

#### Inputs 

1. We will need the `phytree_preprocessed_physeq`, which includes a rooted tree (ideally within the archaea!) that we created in `analysis/04B_Phylogenetic_Tree_Inspection.Rmd`. 

#### Outputs 

1. Calculated biodiversity measures (Hill numbers) across every sample. 
2. Figures to include in our scientific paper that visualize the data as it relates to the scientific question.
3. Statistical tests conveying the measured and quantified changes and patterns in biodiversity.

### `06_Ordination.Rmd`
#### Goals 

1. Load in phyloseq data with rooted tree & colors and functions.  
2. Evaluate sequencing depth and remove samples, if needed.  
3. Normalize the read counts between samples.  
4. Calculate community **dis**similarities. Numbers between 0 and 1. If 0, completely similar versus if they are 1, then they're completely dissimilar.   
    a. **Sorensen**: Shared Species as a binary value: Abundance-unweighted 
    b. **Bray-Curtis**: Shared Abundant species: Abundance-weighted
    c. **(Abundance-)Weighted UNIFRAC**: Consider Abundant Species and where they fall on the tree  
5. Run statistics with functions from the vegan R package: 
    a. PERMANOVA with `adonis2()`.
    b. betadispR with `betadisper()` and `permutest()`. 
6. Visualize the community data with two unconstrained Ordinations:  
    a. **PCoA**: Linear Method. Eigenvalue = how much variation is explained by each axis. Choose to view axis 1, 2, 3, etc. and plot them together.  
    b. **NMDS**: Non-linear. Smush multiple Dimensions into 2 or 3 axes. Need to report Stress value (ideally <0.15).  

#### Inputs 

1. We will need the `phytree_preprocessed_physeq.RData`, which includes a rooted tree that we created in `analysis/04B_Phylogenetic_Tree_Inspection.Rmd`. 

#### Outputs 

1. Calculated beta-diversity dissimilarity measures (*e.g.* Sorensen, Bray-Curtis, abundance-unweighted and -weighted UniFrac) across every sample. 
2. Ordination figures (*i.e.,* PCoA/NMDS) to include in the scientific paper that visualize the data as it relates to the scientific question.
3. Statistical tests (*i.e.,* PERMANOVA & betadisper) conveying the measured and quantified changes and patterns in biodiversity.

### `07_Composition.Rmd`
#### Goals

In this file, we will perform compositional analysis of our scaled/noramlized/rarefied microbial dataset! 

1. Load in scaled/normalized phyloseq object. 
2. Calculate the relative abundances of taxonomic groups at various levels: 
    A. Phylum
    B. Genus
    C. ASV 
3. Plot them, and narrow in on specific taxnomic group of interest

#### Inputs 

1. We will need the `scaled_physeq.RData`, which includes a rooted tree that we created in `analysis/06_Ordination/scaled_physeq.RData`. 

#### Outputs 

1. Beautiful visualizations of microbial taxa and how they vary across parameters related to our study: station (categorical) and salinity (continuous).
2. Run some stats! 

