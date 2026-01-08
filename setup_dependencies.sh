#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "   WESscDRS - ONE-TIME SETUP"
echo "==========================================="
echo

echo "Checking Python installation..."

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python is not installed."
    INSTALL_PYTHON=true
else
    PY_VER=$(python3 - <<'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
    echo "Found Python $PY_VER"
    if [[ "$PY_VER" < "3.12" ]]; then
        echo "Python >=3.12 is required."
        INSTALL_PYTHON=true
    else
        INSTALL_PYTHON=false
    fi
fi

# If you actually want to auto-install Python 3.12 here, add apt logic.
# For now we keep your behavior: just detect and proceed.

cd "$HOME/PSC-project/PSC-scDRS"
ENV_NAME="pythonENV"

if [ ! -d "$ENV_NAME" ]; then
    echo ">>> Creating Python virtual environment ($ENV_NAME)"
    python3 -m venv "$ENV_NAME"
else
    echo ">>> Python virtual environment ($ENV_NAME) already exists, reusing"
fi

echo ">>> Activating environment"
# shellcheck disable=SC1090
source "$ENV_NAME/bin/activate"

# Requirements file: define BEFORE using it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="$SCRIPT_DIR/env/requirements.txt"

echo ">>> Installing Python dependencies from $REQ_FILE"
if [ ! -f "$REQ_FILE" ]; then
    echo "❌ requirements.txt not found at $REQ_FILE"
    exit 1
fi

python3 -m pip install --upgrade pip
python3 -m pip install -r "$REQ_FILE"

echo
echo ">>> Python environment ready."
echo

### 2. Install HTSlib + BCFtools (only if not yet there)
cd "$HOME/PSC-project"
BCFTOOLS_DIR="bcftools"

if [ ! -d "$BCFTOOLS_DIR/.git" ]; then
  echo ">>> Cloning bcftools (with submodules) into $BCFTOOLS_DIR"
  git clone --recurse-submodules https://github.com/samtools/bcftools.git "$BCFTOOLS_DIR"
else
  echo ">>> bcftools already exists in $BCFTOOLS_DIR, updating"
  git -C "$BCFTOOLS_DIR" pull --rebase
  git -C "$BCFTOOLS_DIR" submodule update --init --recursive
fi

echo ">>> Building bcftools (make)"
make -C "$BCFTOOLS_DIR"

echo ">>> Done. Binary is at: $HOME/PSC-project/$BCFTOOLS_DIR/bcftools"

### 3. Download official dbSNP GRCh38 master catalog
cd "$HOME/PSC-project"
mkdir -p vcf
cd vcf
echo ">>> Installing dbSNP master rsID catalogue (GRCh38)"
wget -nc https://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/00-All.vcf.gz
wget -nc https://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/00-All.vcf.gz.tbi

### 4. Install MAGMA
cd "$HOME/PSC-project"
mkdir -p magma
cd magma

curl -L -o g1000_eur.zip \
  "https://vu.data.surf.nl/index.php/s/VZNByNwpD8qqINe/download?path=%2F&files=g1000_eur.zip"
unzip -t g1000_eur.zip
unzip -o g1000_eur.zip

curl -L -o NCBI38.zip \
  "https://vu.data.surf.nl/index.php/s/yj952iHqy5anYhH/download?path=%2F&files=NCBI38.zip"
unzip -t NCBI38.zip
unzip -o NCBI38.zip

echo
echo "==========================================="
echo "   ONE-TIME SETUP COMPLETED"
echo "==========================================="
