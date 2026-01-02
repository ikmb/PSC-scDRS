#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "   WESscDRS - ONE-TIME SETUP"
echo "==========================================="
echo

ENV_NAME="PSC-project-python"

if [ ! -d "$ENV_NAME" ]; then
    echo ">>> Creating Python virtual environment ($ENV_NAME)"
    python3 -m venv "$ENV_NAME"
else
    echo ">>> Python virtual environment ($ENV_NAME) already exists, reusing"
fi

echo ">>> Activating environment"
# shellcheck disable=SC1091
source "$ENV_NAME/bin/activate"

echo ">>> Installing Python dependencies from https://github.com/ikmb/PSC-scDRS/edit/main/env/requirements.txt"
pip install --upgrade pip
pip install -r requirements.txt

echo
echo ">>> Python environment ready."
echo
### 2. Install HTSlib + BCFtools (only if not yet there)
cd "$HOME/PSC-scDRS"
mkdir -p reference
HTSLIB_DIR="reference/htslib"
BCFTOOLS_DIR="reference/bcftools"

if [ ! -d "$HTSLIB_DIR" ]; then
    echo ">>> Cloning htslib into $HTSLIB_DIR"
    git clone --recurse-submodules https://github.com/samtools/htslib.git "$HTSLIB_DIR"
else
    echo ">>> htslib already exists in $HTSLIB_DIR, skipping clone"
fi

if [ ! -d "$BCFTOOLS_DIR" ]; then
    echo ">>> Cloning bcftools into $BCFTOOLS_DIR"
    git clone https://github.com/samtools/bcftools.git "$BCFTOOLS_DIR"
else
    echo ">>> bcftools already exists in $BCFTOOLS_DIR, skipping clone"
fi

echo ">>> Building bcftools (make)"
cd "$BCFTOOLS_DIR"
make
cd ../../

### 3. Install MAGMA
cd "$HOME/PSC-scDRS"
mkdir -p reference/magma
cd reference/magma
wget https://ctg.cncr.nl/software/MAGMA/ref_data/g1000_eur.zip
unzip g1000_eur.zip

cd "$HOME/PSC-scDRS/reference/magma"
curl -L -o NCBI38.zip "https://vu.data.surf.nl/index.php/s/yj952iHqy5anYhH"
unzip -o NCBI38.zip

echo
echo "==========================================="
echo "   ONE-TIME SETUP COMPLETED"
echo "==========================================="

