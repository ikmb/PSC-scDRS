#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: Seirana

This program generates a file in the desired format for the bcftools function.

input: 
    './scDRS/data/sample_single_marker_test.zip'
output:
    ./scDRS/output/bcf_variants.vcf'
"""

from IPython import get_ipython
import os

import sys
sys.path.append('./scDRS/code/')

import pandas as pd


file = './scDRS/data/sample_single_marker_test.zip'
reg = pd.read_csv(
    file,
    sep=r"\s+",
    compression="zip"
)
reg["reg_index"] = range(len(reg))

third_col = reg.columns[2]
reg[third_col] = reg[third_col].astype(str).str.removeprefix("chr")

bcf = pd.DataFrame({
    "#CHROM": reg.iloc[:, 0],
    "POS": reg.iloc[:, 1],
    "ID": ".",
    "REF": reg.iloc[:, 3],
    "ALT": reg.iloc[:, 4],
    "QUAL": ".",
    "FILTER": ".",
    "INFO": "."
})

with open('./scDRS/output/bcf_variants.vcf', 'w') as f:
    f.write("##fileformat=VCFv4.2\n")
    bcf.to_csv(f, sep="\t", index=False)
