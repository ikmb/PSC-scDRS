#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: Seirana

Runs scDRS for a given trait and tissue.

input:
    <repo>/data/{tissue}.h5ad   (or <repo>/data/HumanLiverHealthyscRNAseqData.zip as source)
    <repo>/output/{trait}_geneset.gs

output:
    <repo>/output/{tissue}_cov.tsv
    <repo>/output/{trait}.full_score.gz  (and other scDRS outputs)
    <repo>/bin/figures/cell_ontology_classes_{tissue}.png
    <repo>/bin/figures/associated_cells_of_{tissue}_to_{trait}.png
"""

import os
import sys
import zipfile
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import scanpy as sc
import subprocess

import scdrs_

warnings.filterwarnings("ignore")


def get_paths() -> tuple[Path, Path, Path, Path]:
    """
    Prefer env vars exported by PSC_scDRS_run.sh:
      REPO_DIR, BIN_DIR, DATA_DIR, OUT_DIR
    Fallback: infer repo as parent of this script's directory (bin/ -> repo/)
    """
    repo_env = os.environ.get("REPO_DIR")
    bin_env = os.environ.get("BIN_DIR")
    data_env = os.environ.get("DATA_DIR")
    out_env = os.environ.get("OUT_DIR")

    if repo_env:
        repo_dir = Path(repo_env).resolve()
        bin_dir = Path(bin_env).resolve() if bin_env else (repo_dir / "bin")
        data_dir = Path(data_env).resolve() if data_env else (repo_dir / "data")
        out_dir = Path(out_env).resolve() if out_env else (repo_dir / "output")
        return repo_dir, bin_dir, data_dir, out_dir

    script_dir = Path(__file__).resolve().parent
    repo_dir = script_dir.parent
    bin_dir = repo_dir / "bin"
    data_dir = repo_dir / "data"
    out_dir = repo_dir / "output"
    return repo_dir, bin_dir, data_dir, out_dir


def find_compute_score_py() -> Path:
    """
    Find scDRS compute_score.py.
    Priority:
      1) env var SCDRS_DIR (expects compute_score.py inside it)
      2) <repo>/scDRS/compute_score.py
      3) ~/scDRS/compute_score.py
    """
    scdrs_dir = os.environ.get("SCDRS_DIR")
    candidates = []

    if scdrs_dir:
        candidates.append(Path(scdrs_dir) / "compute_score.py")

    # common locations
    repo_dir, _, _, _ = get_paths()
    candidates.append(repo_dir / "scDRS" / "compute_score.py")
    candidates.append(Path.home() / "scDRS" / "compute_score.py")

    for c in candidates:
        if c.exists():
            return c.resolve()

    raise FileNotFoundError(
        "Could not find scDRS compute_score.py. "
        "Set env var SCDRS_DIR to the folder containing compute_score.py, "
        "or place scDRS under <repo>/scDRS/."
    )


# -------------------------
# User-configurable settings
# -------------------------
trait = os.environ.get("TRAIT", "PSC")
tissue = os.environ.get("TISSUE", "Liver")
hm = os.environ.get("SCDRS_S_
