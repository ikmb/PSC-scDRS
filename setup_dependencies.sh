#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "   PSC-scDRS - ONE-TIME SETUP"
echo "==========================================="
echo

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
make -C "$HTSLIB_PATH"

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
command -v bgzip >/dev/null 2>&1 || { echo "❌ bgzip not found in PATH after build"; exit 1; }
command -v bcftools >/dev/null 2>&1 || { echo "❌ bcftools not found in PATH after build"; exit 1; }
echo "bgzip:   $(command -v bgzip)"
echo "bcftools: $(command -v bcftools)"
echo
echo ">>> If you want these tools available in new terminals, add this line to your shell rc (e.g. ~/.bashrc):"
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
mkdir -p "$SCRIPT_DIR/magma"
cd "$SCRIPT_DIR/magma"

echo ">>> Downloading MAGMA reference data"
curl -L -o g1000_eur.zip \
  "https://vu.data.surf.nl/index.php/s/VZNByNwpD8qqINe/download?path=%2F&files=g1000_eur.zip"
unzip -t g1000_eur.zip
unzip -o g1000_eur.zip

curl -L -o NCBI38.zip \
  "https://vu.data.surf.nl/index.php/s/yj952iHqy5anYhH/download?path=%2F&files=NCBI38.zip"
unzip -t NCBI38.zip
unzip -o NCBI38.zip

cd "$SCRIPT_DIR"
echo
echo "==========================================="
echo "   ONE-TIME SETUP COMPLETED"
echo "==========================================="
