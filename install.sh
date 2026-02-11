#!/bin/bash

set -eu  # Interrompe em caso de erro

INITIAL_FOLDER=$(pwd)

#============================================================
# Constants
#============================================================

# Env temporary folder
TEMP_DIR="/tmp/conda_env_$$"

# Possible files inside remote env folders
REMOTE_ENV_FILES=("environment.yml" "install.R")

# Available envs
ENV_NAMES=("r-geo" "py-geo" "apsim")


#============================================================
# Functions
#============================================================

download_if_exists() {
    local remote_env_name="$1"
    local file="$2"

    local url="https://raw.githubusercontent.com/luanabeckerdaluz/conda-geo-rpy/main/envs/${remote_env_name}/${file}"
    
    # echo "  DEBUG URL: $url"
    if curl -s -I "$url" 2>/dev/null | head -n 1 | grep -q "200"; then
        echo "  📥 Downloading $file..."
        curl -s -L -o "$file" "$url"
        return 0
    else
        return 1
    fi
}

clean_tmp_folder() {
    echo "🧹 Cleaning temporary folder '${TEMP_DIR}..."
    rm -rf "$TEMP_DIR"
}

aborting_installation() {
    echo "❌ ERROR: Aborting installation!"
    exit 0
}

activate_conda_env() {
    local env_name="$1"

    echo "  🔧 Activating '${env_name}' conda env..."
    # source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate ${env_name}
    # Check if env was activated
    if [ "$CONDA_DEFAULT_ENV" != "${env_name}" ]; then
        echo "❌ INTERNAL ERROR: Could not activate '${env_name}' env. Please, contact support!";
        aborting_installation
    fi
}

deactivate_conda_env() {
    echo "  🔧 Deactivating env..."
    conda deactivate

    # if [ "$CONDA_DEFAULT_ENV" != "base" ]; then
    #     echo "❌ INTERNAL ERROR: After deactivating, current env '${CONDA_DEFAULT_ENV}' is different from 'base' env!";
    #     aborting_installation
    # fi
}

check_r_installation() {
    if command -v R &> /dev/null; then
        echo "  🔧 Checking R installation..."
        echo "  $(R --version | head -n 1)"
        # Instalar pacotes R adicionais se necessário
        # (adicione aqui pacotes específicos)
        echo "  ✅ R is installed!"
        return 0;
    else
        echo "❌ ERROR: R is not installed!"
        aborting_installation
    fi
}

check_conda_installation() {
    if ! command -v conda &> /dev/null; then
        echo "❌ ERROR: Conda not found. Please, install miniconda from 'https://www.anaconda.com/docs/getting-started/miniconda'!"
        aborting_installation
    fi
}

# Function to be triggered in case of any error
clean() {
    clean_tmp_folder
    cd ${INITIAL_FOLDER}
    aborting_installation
}

# Register function to run in case of any error
trap clean ERR


#============================================================
# Check Conda installation
#============================================================
check_conda_installation


#============================================================
# User choose environment
#============================================================

# TODO: Add options "Complete Installation" or "Only register kernel Jupyter" ?

echo "Select the environment you want to install:"
echo ""
for i in "${!ENV_NAMES[@]}"; do
    printf "  %d) %s\n" $((i+1)) "${ENV_NAMES[$i]}"
done
echo ""
read -p "❓ Insert option: " choice

# Validate
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#ENV_NAMES[@]}" ]; then aborting_installation; fi;

# Get env name
index=$((choice-1))
ENV_NAME="${ENV_NAMES[$index]}"
REMOTE_ENV_NAME=${ENV_NAME}
# Confirm
read -p "❓ You chose '${ENV_NAME}'. Confirm installation? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then aborting_installation; fi;

# Check local env name
read -p "❓ Name you conda env (default: '${ENV_NAME}'): " NEW_CONDA_ENV_NAME
# Update ENV_NAME if user chose a new name 
if [ ! -z "$NEW_CONDA_ENV_NAME" ]; then
    if [[ "$NEW_CONDA_ENV_NAME" =~ [/:#\ ] || "$NEW_CONDA_ENV_NAME" == "base" || "$NEW_CONDA_ENV_NAME" == "root" ]]; then
        echo "❌ ERROR: Invalid environment name! Cannot be empty or contain / : # ' ' or be 'base'/'root'"
        aborting_installation
    fi

    # Confirm
    read -p "❓ You named your conda env as '${NEW_CONDA_ENV_NAME}'. Confirm? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then aborting_installation; fi;
    
    ENV_NAME=$NEW_CONDA_ENV_NAME
fi


#============================================================
# Check if env already exists
#============================================================

echo "..."
# echo "🔧 Checking if env '${ENV_NAME}' already exists..."
if conda env list | grep -q "^${ENV_NAME}\s"; then
    echo "❌ ERROR: Conda environment '${ENV_NAME}' already exists! Please, remove it manually before continue using 'conda env remove --name ${ENV_NAME} -y'."
    aborting_installation
fi

#============================================================
# Create tmp folder
#============================================================

# Create tmp folder
mkdir -p "${TEMP_DIR}"


#============================================================
# Download remote files
#============================================================

echo "📥 Downloading required files..."

# Create temporary dir and download required files
cd "${TEMP_DIR}"
if ! download_if_exists ${REMOTE_ENV_NAME} "environment.yml"; then
    echo "❌ INTERNAL ERROR: environment.yml file not found. Please, contact support!"
    rm -rf "${TEMP_DIR}"
    exit 1
fi
for file in "${REMOTE_ENV_FILES[@]:1}"; do  # Skip first (environment.yml)
    download_if_exists ${REMOTE_ENV_NAME} "$file" || true
done

echo "✅ The files were downloaded successfully!"
echo "..."


#============================================================
# Create environment
#============================================================

# Create env based on environment.yml file
echo "🔧 Creating env '${ENV_NAME}'..."

# sleep 2
conda env create -f ${TEMP_DIR}/environment.yml -n "$ENV_NAME"

# Check if conda env was created successfully
if conda env list | grep -q "^${ENV_NAME}\s"; then
    echo "✅ Conda env '${ENV_NAME}' was created successfully!"
else 
    echo "❌ ERROR: Could not create Conda environment '${ENV_NAME}'!"
    aborting_installation
fi
echo "..."



# # TODO: Register as Jupyter Kernel?
# python3 -m ipykernel install --name rapsimx --prefix=$ENV_NAME --display-name=$ENV_NAME
# Rscript -e "options(warn=2); IRkernel::installspec(name = 'rgeo', displayname = 'R APSIMx')"



#============================================================
# Install R dependencies
#============================================================

if [[ -f "${TEMP_DIR}/install.R" ]]; then
    echo "🔧 Since this env depends on a 'install.R' file, I will activate the environment and run it!"

    # Activate env
    activate_conda_env ${ENV_NAME}
    
    # Check if R is installed
    check_r_installation

    echo "  🔧 Running R script 'install.R'..."
    echo "   ..."
    Rscript ${TEMP_DIR}/install.R
    echo "   ..."
    
    # Deactivate env
    deactivate_conda_env
fi
echo "..."

# Clean temporary files
clean_tmp_folder
echo "..."

# Final instructions
cd ${INITIAL_FOLDER}
echo "====================================================="
echo "ℹ️  Conda env ${ENV_NAME} configured successfully!"
echo "ℹ️  To deactivate: 'conda deactivate'"
echo "ℹ️  To activate: 'conda activate $ENV_NAME'"
echo "ℹ️  To remove: 'conda env remove -n $ENV_NAME -y'"
echo "====================================================="