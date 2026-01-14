#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "   PSC-scDRS - ONE-TIME SETUP"
echo "==========================================="
echo

# --------------------------
# 0) Basic tool checks
# --------------------------
for cmd in git make gcc wget curl unzip; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    echo "On Ubuntu/Debian, install with:"
    echo "  sudo apt update && sudo apt install -y git build-essential wget curl unzip"
    exit 1
  fi
done

echo "Checking Python installation..."

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python is not installed (python3 not found)."
  echo "Install Python 3.12 (and python3.12-venv) and re-run."
  exit 1
fi

PY_VER=$(python3 - <<'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
echo "Found Python $PY_VER"

if [[ "$PY_VER" < "3.12" ]]; then
  echo "Python >=3.12 is required."
  exit 1
fi

# Work inside the repo (script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --------------------------
# 1) Python virtual env + deps
# --------------------------
ENV_NAME="pythonENV"
VENV_PATH="$SCRIPT_DIR/$ENV_NAME"

if [ ! -d "$VENV_PATH" ]; then
  echo ">>> Creating Python virtual environment ($ENV_NAME)"
  python3 -m venv "$VENV_PATH"
else
  echo ">>> Python virtual environment ($ENV_NAME) already exists, reusing"
fi

if [ ! -f "$VENV_PATH/bin/activate" ]; then
  echo "Virtual environment activation script not found: $VENV_PATH/bin/activate"
  echo "Try removing $VENV_PATH and re-running setup_dependencies.sh"
  exit 1
fi

echo ">>> Activating environment"
# shellcheck disable=SC1090
source "$VENV_PATH/bin/activate"

REQ_FILE="$SCRIPT_DIR/env/requirements.txt"
echo ">>> Installing Python dependencies from $REQ_FILE"

if [ ! -f "$REQ_FILE" ]; then
  echo "requirements.txt not found at $REQ_FILE"
  exit 1
fi

python3 -m pip install --upgrade pip
python3 -m pip install -r "$REQ_FILE"

echo
echo ">>> Python environment ready."
echo

# --------------------------
# 2) HTSlib + BCFtools
# --------------------------
HTSLIB_DIR="htslib"
BCFTOOLS_DIR="bcftools"
HTSLIB_PATH="$SCRIPT_DIR/$HTSLIB_DIR"
BCFTOOLS_PATH="$SCRIPT_DIR/$BCFTOOLS_DIR"

# htslib (needs submodules: htscodecs)
if [ ! -d "$HTSLIB_PATH/.git" ]; then
  echo ">>> Cloning htslib (with submodules) into $HTSLIB_DIR"
  git clone --recurse-submodules https://github.com/samtools/htslib.git "$HTSLIB_PATH"
else
  echo ">>> htslib already exists in $HTSLIB_DIR, updating"
  git -C "$HTSLIB_PATH" pull --rebase
  git -C "$HTSLIB_PATH" submodule update --init --recursive
fi

echo ">>> Building htslib (provides bgzip/tabix)"
if ! make -C "$HTSLIB_PATH"; then
  echo "htslib build failed."
  echo "On Ubuntu/Debian you may need:"
  echo "  sudo apt install -y libcurl4-openssl-dev libbz2-dev liblzma-dev"
  exit 1
fi

# bcftools
if [ ! -d "$BCFTOOLS_PATH/.git" ]; then
  echo ">>> Cloning bcftools (with submodules) into $BCFTOOLS_DIR"
  git clone --recurse-submodules https://github.com/samtools/bcftools.git "$BCFTOOLS_PATH"
else
  echo ">>> bcftools already exists in $BCFTOOLS_DIR, updating"
  git -C "$BCFTOOLS_PATH" pull --rebase
  git -C "$BCFTOOLS_PATH" submodule update --init --recursive
fi

echo ">>> Building bcftools (make)"
make -C "$BCFTOOLS_PATH" clean || true
make -C "$BCFTOOLS_PATH"

# Make bgzip/tabix/bcftools available in THIS shell session
export PATH="$HTSLIB_PATH:$BCFTOOLS_PATH:$PATH"

echo
echo ">>> Tool availability check"
command -v bgzip >/dev/null 2>&1 || { echo "bgzip not found in PATH after build"; exit 1; }
command -v bcftools >/dev/null 2>&1 || { echo "bcftools not found in PATH after build"; exit 1; }
echo "bgzip:    $(command -v bgzip)"
echo "bcftools: $(command -v bcftools)"
echo
echo ">>> For new terminals, add to ~/.bashrc:"
echo "export PATH=\"$HTSLIB_PATH:$BCFTOOLS_PATH:\$PATH\""
echo

# --------------------------
# 3) Download dbSNP GRCh38 master catalog
# --------------------------
mkdir -p "$SCRIPT_DIR/vcf"
cd "$SCRIPT_DIR/vcf"

echo ">>> Downloading dbSNP master rsID catalogue (GRCh38)"
wget -nc https://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/00-All.vcf.gz
wget -nc https://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/00-All.vcf.gz.tbi

cd "$SCRIPT_DIR"
echo

# --------------------------
# 4) Install MAGMA resources
# --------------------------
MAGMA_REF_DIR="$SCRIPT_DIR/magma"
mkdir -p "$MAGMA_REF_DIR"
cd "$MAGMA_REF_DIR"

echo ">>> Downloading MAGMA reference data (1000G EUR + NCBI38 gene locations)"

# 1000G EUR reference panel
if [[ ! -f "g1000_eur.bed" || ! -f "g1000_eur.bim" || ! -f "g1000_eur.fam" ]]; then
  curl -L -o g1000_eur.zip \
    "https://vu.data.surf.nl/index.php/s/VZNByNwpD8qqINe/download?path=%2F&files=g1000_eur.zip"
  unzip -t g1000_eur.zip
  unzip -o g1000_eur.zip
  rm -f g1000_eur.zip
else
  echo ">>> Reference panel already present: $MAGMA_REF_DIR/g1000_eur.{bed,bim,fam}"
fi

# NCBI38 gene location file (GRCh38/hg38)
if [[ ! -f "NCBI38.gene.loc" ]]; then
  curl -L -o NCBI38.zip \
    "https://vu.data.surf.nl/index.php/s/yj952iHqy5anYhH/download?path=%2F&files=NCBI38.zip"
  unzip -t NCBI38.zip
  unzip -o NCBI38.zip
  rm -f NCBI38.zip
else
  echo ">>> Gene location file already present: $MAGMA_REF_DIR/NCBI38.gene.loc"
fi

# Hard fail if key resources are missing
[[ -f "$MAGMA_REF_DIR/NCBI38.gene.loc" ]] || { echo "ERROR: Missing $MAGMA_REF_DIR/NCBI38.gene.loc"; exit 1; }
[[ -f "$MAGMA_REF_DIR/g1000_eur.bed" && -f "$MAGMA_REF_DIR/g1000_eur.bim" && -f "$MAGMA_REF_DIR/g1000_eur.fam" ]] || {
  echo "ERROR: Missing one of g1000_eur.{bed,bim,fam} in $MAGMA_REF_DIR"
  exit 1
}

# --------------------------
# 4b) Install MAGMA binary (repo-local, reproducible)
# --------------------------
MAGMA_BIN_DIR="$SCRIPT_DIR/tools/magma"
mkdir -p "$MAGMA_BIN_DIR"

# If magma already exists in this repo, do nothing; otherwise download it.
MAGMA_EXE="$(find "$MAGMA_BIN_DIR" -maxdepth 4 -type f -name magma -perm -111 | head -n 1 || true)"
if [[ -z "$MAGMA_EXE" ]]; then
  echo ">>> Installing MAGMA binary into repo: $MAGMA_BIN_DIR"
  MAGMA_ZIP="$MAGMA_BIN_DIR/magma_v1.10.zip"
  curl -L -o "$MAGMA_ZIP" "https://vu.data.surf.nl/index.php/s/zkKbNeNOZAhFXZB/download"
  unzip -o "$MAGMA_ZIP" -d "$MAGMA_BIN_DIR"
  rm -f "$MAGMA_ZIP"

  MAGMA_EXE="$(find "$MAGMA_BIN_DIR" -maxdepth 4 -type f -name magma -perm -111 | head -n 1 || true)"
  [[ -n "$MAGMA_EXE" ]] || { echo "ERROR: MAGMA binary not found after unzip in $MAGMA_BIN_DIR"; exit 1; }
  chmod +x "$MAGMA_EXE"
else
  echo ">>> Repo-local MAGMA already present: $MAGMA_EXE"
fi

# IMPORTANT: prefer repo-local magma over any system-installed magma
export PATH="$(dirname "$MAGMA_EXE"):$PATH"
hash -r

command -v magma >/dev/null 2>&1 || { echo "ERROR: MAGMA not available in PATH"; exit 1; }

echo ">>> Using MAGMA: $(command -v magma)"
echo ">>> MAGMA version: $(magma --version 2>/dev/null | head -n 1 || true)"
echo
echo ">>> For new terminals, optionally add to ~/.bashrc:"
echo "export PATH=\"$(dirname "$MAGMA_EXE"):\$PATH\""
echo
echo ">>> MAGMA refs:"
echo "  - LD ref prefix: $MAGMA_REF_DIR/g1000_eur"
echo "  - Gene loc file: $MAGMA_REF_DIR/NCBI38.gene.loc"

cd "$SCRIPT_DIR"
echo "==========================================="
echo "   ONE-TIME SETUP COMPLETED"
echo "==========================================="
