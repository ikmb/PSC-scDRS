#========================================================================
#input:
# 	"$HOME/PSC-project/PSC-scDRS/output/bcf_variants.vcf
#	"$HOME/PSC-project/00-All.vcf.gz
# output:
#	"$HOME/PSC-project/PSC-scDRS/output/bcf_variants.vcf.gz
#	"$HOME/PSC-project/PSC-scDRS/output/variants_with_rsID.vcf
#========================================================================
##!/bin/bash

input_vcf="$HOME/PSC-project/PSC-scDRS/output/bcf_variants.vcf"
output_vcf="$HOME/PSC-project/PSC-scDRS/output/bcf_variants.vcf.gz"
annotated_vcf="$HOME/PSC-project/PSC-scDRS/output/variants_with_rsID.vcf"

if [ -f "$input_vcf" ]; then
    bgzip -f -c "$input_vcf" > "$output_vcf"
    bcftools index $output_vcf
    bcftools annotate -a $HOME/PSC-project/vcf/00-All.vcf.gz -c ID $output_vcf -o $annotated_vcf
else
    echo "File $input_vcf does not exist!"
fi
