### 1. Install Python dependencies
#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "   WESscDRS - ONE-TIME SETUP"
echo "==========================================="
echo

apt install python3.12-venv

cd "$HOME/PSC-project"
ENV_NAME="pythonENV"

if [ ! -d "$ENV_NAME" ]; then
    echo ">>> Creating Python virtual environment ($ENV_NAME)"
    python3 -m venv "$ENV_NAME"
else
    echo ">>> Python virtual environment ($ENV_NAME) already exists, reusing"
fi

echo ">>> Activating environment"
source "$ENV_NAME/bin/activate"
                      
REQ_FILE="$HOME/PSC-project/PSC-scDRS/env/requirements.txt"
echo ">>> Installing Python dependencies from $REQ_FILE"
pip install --upgrade pip
pip install -r "$REQ_FILE"
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

echo ">>> Done. Binary is at: $REPO_DIR/$BCFTOOLS_DIR/bcftools"

### 3.  Download official dbSNP GRCh38 master catalog
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
