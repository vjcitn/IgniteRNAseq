FROM bioconductor/bioconductor_docker:devel

WORKDIR /home/rstudio

COPY --chown=rstudio:rstudio . /home/rstudio/

USER root

RUN apt-get update && sudo apt-get install -y samtools minimap2 aria2 

USER rstudio

RUN Rscript -e "options(repos = c(CRAN = 'https://cran.r-project.org')); BiocManager::install('Biostrings', ask=FALSE)" && \
    aria2c -x 16 "https://zenodo.org/records/12751214/files/filtered_sorted.bam?download=1" && \
    aria2c "https://zenodo.org/records/12751214/files/filtered_sorted.bam.bai?download=1" && \
    aria2c -x 16 "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh38.primary_assembly.genome.fa.gz" && Rscript -e 'library(Biostrings); genome <- readDNAStringSet("GRCh38.primary_assembly.genome.fa.gz"); names(genome) <- sapply(names(genome), function(x) strsplit(x, " ")[[1]][1]); genome <- genome[c("chr19", "chrM")]; writeXStringSet(genome, "subset_GRCh38.fa")' && rm GRCh38.primary_assembly.genome.fa.gz && \
    aria2c -x 16 "https://zenodo.org/records/12770737/files/sce_lib10.qs?download=1" && \
    aria2c -x 16 "https://zenodo.org/records/12770737/files/sce_lib90.qs?download=1" && \
    Rscript -e "options(repos = c(CRAN = 'https://cran.r-project.org')); devtools::install('.', dependencies=TRUE, build_vignettes=TRUE, repos = BiocManager::repositories())" && \
    Rscript -e "basilisk::basiliskRun(env = FLAMES:::flames_env, fun = function(){})" && \
    Rscript -e "library(FLAMES); example(find_isoform); find_isoform( \
       annotation = annotation, genome_fa = genome_fa,   \
       genome_bam = file.path(outdir, 'align2genome.bam'),   \
       outdir = outdir, config = config)"
     

USER root
