#==============================================================================================================
# This program applies MAGMA gene-based test on data
# input:
#	N=5023 equal to the all samples in the study, cases and controls
#	"$HOME/PSC-project/PSC-scDRS/output/files_for_MAGMA.txt"
#	"$HOME/PSC-project/PSC-scDRS/output/files_for_step2.txt"
#	"$HOME/PSC-project/PSC-scDRS/output/files_step1.genes.annot"
# output:
#	"$HOME/PSC-project/PSC-scDRS/output/files_step1"
#	"$HOME/PSC-project/PSC-scDRS/output/files_step2"
#==============================================================================================================
#!/bin/bash

annot_file="$HOME/PSC-project/PSC-scDRS/output/files_for_MAGMA.txt"
step1_out="$HOME/PSC-project/PSC-scDRS/output/files_step1"
step2_pval="$HOME/PSC-project/PSC-scDRS/output/files_for_step2.txt"
step1_genes_annot="$HOME/PSC-project/PSC-scDRS/output/files_step1.genes.annot"
step2_out="$HOME/PSC-project/PSC-scDRS/output/files_step2"

magma --annotate --snp-loc $annot_file --gene-loc $HOME/PSC-project/magma/NCBI38/NCBI38.gene.loc --out $step1_out
magma --bfile $HOME/PSC-project/magma/g1000_eur/g1000_eur --pval $step2_pval N=5023 --gene-annot $step1_genes_annot --out $step2_out
