#!/bin/bash

set -eu  # Interrompe em caso de erro

VERSION=1.0.7

#============================================================
# Input parameters
#============================================================

error_message() {
    local msg="$1"
    echo "❌ ERROR: ${msg}!"
}

# Install from local folder or remote URLs
USE_LOCAL_OR_REMOTE_FILES="remote"

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--local)
            USE_LOCAL_OR_REMOTE_FILES="local" 
            echo "🔧 Installing Using local files..."
            ;;
        -v|--version)
            echo "preconfigured-conda-envs | Version: $VERSION"
            exit 0
            ;;
        *)
            error_message "Invalid parameter! Available parameters are --local and --version"
            exit 1
            ;;
    esac
    shift
done

#============================================================
# Constants
#============================================================

# Env temporary folder
TEMP_DIR="/tmp/conda_env_$$"

# Envs files (not all are required)
ENV_AVAILABLE_FILES=("environment.yml" "pkgs-to-install-using-pak.yml" "pkgs-to-install-from-source.yml" "config" "run-before-install-from-source.sh")

# Tool scripts
TOOL_AVAILABLE_SCRIPTS=("install_pak.R" "install_source.R")

# Available envs
ENV_NAMES=("r-geo" "py-geo" "apsim-v1", "apsim-debian-bullseye")

# Set GitHub variables
GITHUB_USER=luanabeckerdaluz
GITHUB_REPO=preconfigured-conda-envs
GITHUB_BRANCH=main

#============================================================
# Functions
#============================================================

retrieve_file() {
    # Input parameters
    local env_path_from_root="$1"
    local file="$2"
    local dest_dir="$3"

    # If using local files, copy local files to temp dir
    if [ "$USE_LOCAL_OR_REMOTE_FILES" = "local" ]; then
        echo "  📥 Copying ${file} to folder ${dest_dir}..."
        cp ../${env_path_from_root}/${file} ${dest_dir}
    # If using remote files, download files from GitHub
    else
        curl_without_cache() {
            curl --no-keepalive --http1.1 \
                -H 'Cache-Control: no-cache, no-store, must-revalidate' \
                -H 'Pragma: no-cache' \
                "$@"
        }

        local url="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${env_path_from_root}/${file}"

        if curl_without_cache -s -I "${url}" 2>/dev/null | head -n 1 | grep -q "200"; then
            echo "  📥 Downloading ${file} into folder ${dest_dir}..."
            curl_without_cache -s -L -o "${dest_dir}/${file}" "${url}"
            return 0
        else
            return 1
        fi
    fi
}

clean_tmp_folder() {
    echo "🧹 Cleaning temporary folder '${TEMP_DIR}..."
    rm -rf "$TEMP_DIR"
}

aborting_installation() {
    error_message "Aborting installation"
    exit 0
}

activate_conda_env() {
    local env_name="$1"

    echo "  🔧 Activating '${env_name}' conda env..."
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate ${env_name}
    # Check if env was activated
    if [ "$CONDA_DEFAULT_ENV" != "${env_name}" ]; then
        error_message "Could not activate '${env_name}' env. Please, contact support"
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
        error_message "R is not installed"
        aborting_installation
    fi
}

check_conda_installation() {
    if ! command -v conda &> /dev/null; then
        error_message "Conda not found. Please, install miniconda from 'https://www.anaconda.com/docs/getting-started/miniconda'"
        aborting_installation
    fi
}

check_curl_installation() {
    if ! command -v curl &> /dev/null; then
        error_message "curl not found. Please, install curl from apt or conda"
        aborting_installation
    fi
}

# Register function to run in case of any error
trap aborting_installation ERR


#============================================================
# Check pre requisites
#============================================================
check_conda_installation
check_curl_installation

# TODO: Check if it is necessary to accept conda terms on first use:
# conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
# conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r


#============================================================
# User choose environment
#============================================================

# TODO: Check if user want to also register Jupyter kernel

# TODO: Create env from local files

# TODO: Automate PAK remote URL


echo "-----------------------------------------"
echo "preconfigured-conda-envs | Version: $VERSION"
echo "-----------------------------------------"
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
confirm=${confirm:-Y}  # Consider Enter as 'Y'
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then aborting_installation; fi;

# Check local env name
read -p "❓ Name you conda env (default: '${ENV_NAME}'): " NEW_CONDA_ENV_NAME
# Update ENV_NAME if user chose a new name 
if [ ! -z "$NEW_CONDA_ENV_NAME" ]; then
    if [[ "$NEW_CONDA_ENV_NAME" =~ [/:#\ ] || "$NEW_CONDA_ENV_NAME" == "base" || "$NEW_CONDA_ENV_NAME" == "root" ]]; then
        error_message "Invalid environment name! Cannot be empty or contain / : # ' ' or be 'base'/'root'"
        aborting_installation
    fi

    # Confirm
    read -p "❓ You named your conda env as '${NEW_CONDA_ENV_NAME}'. Confirm? (y/n): " confirm
    confirm=${confirm:-Y}  # Consider Enter as 'Y'
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then aborting_installation; fi;
    
    ENV_NAME=$NEW_CONDA_ENV_NAME
fi


#============================================================
# Check if env already exists
#============================================================

echo "..."
# echo "🔧 Checking if env '${ENV_NAME}' already exists..."
if conda env list | grep -q "^${ENV_NAME}\s"; then
    error_message "Conda environment '${ENV_NAME}' already exists! Please, remove it manually before continue using 'conda env remove --name ${ENV_NAME} -y'"
    aborting_installation
fi

#============================================================
# Create tmp folder
#============================================================

# Create temporary folder where tool scripts and env 
# ...files will be placed
mkdir -p "${TEMP_DIR}"


#============================================================
# Download remote files or copy local files
#============================================================

echo "📥 Retrieving env files and tool scripts..."

# Download/copy env files
if ! retrieve_file "envs/${REMOTE_ENV_NAME}" "environment.yml" ${TEMP_DIR}; then
    error_message "environment.yml file not found. Please, contact support"
    rm -rf "${TEMP_DIR}"
    exit 1
fi
for file in "${ENV_AVAILABLE_FILES[@]:1}"; do  # Skip first (environment.yml)
    retrieve_file "envs/${REMOTE_ENV_NAME}" $file ${TEMP_DIR} || true
done

# Download/copy tool scripts
for file in "${TOOL_AVAILABLE_SCRIPTS[@]}"; do
    retrieve_file "src" $file ${TEMP_DIR} || true
done
echo "✅ Env files and tool scripts retrieved successfully!"
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
    error_message "Could not create Conda environment '${ENV_NAME}'"
    aborting_installation
fi
echo "..."



# # TODO: Register Jupyter Kernel?
# python3 -m ipykernel install --name rapsimx --prefix=$ENV_NAME --display-name=$ENV_NAME
# Rscript -e "options(warn=2); IRkernel::installspec(name = 'rgeo', displayname = 'R APSIMx')"



#============================================================
# Install R dependencies
#============================================================

if [[ -f "${TEMP_DIR}/pkgs-to-install-using-pak.yml" ]]; then
    echo "🔧 Since this env contains a 'pkgs-to-install-using-pak.yml' file containing R packages not available on Conda, I will activate the env and install these R packages!"

    # Activate env
    activate_conda_env ${ENV_NAME}

    # Configure LD_LIBRARY_PATH and PKG_CONFIG_PATH and restart env
    conda env config vars set LD_LIBRARY_PATH=$CONDA_PREFIX/lib
    conda env config vars set PKG_CONFIG_PATH=$CONDA_PREFIX/lib/pkgconfig
    deactivate_conda_env
    activate_conda_env ${ENV_NAME}
    
    # Check if R is installed
    check_r_installation

    # Since this env has R packages to be installed using pak, we need to
    # ... open "config" file downloaded to check if we need to install "pak"
    # ... package from source.
    if grep -q "installation_mode=2" ${TEMP_DIR}/config; then
        echo "This environment requires to install some packages from source. Installing..."
        
        echo "   ..."
        echo "  🔧 Running sh script before install R packages from source..."
        source ${TEMP_DIR}/run-before-install-from-source.sh
        echo "   ..."

        echo "   ..."
        echo "  🔧 Running script 'install_source.R'..."
        Rscript ${TEMP_DIR}/install_source.R "${TEMP_DIR}/pkgs-to-install-from-source.yml"
        echo "   ..."
    fi

    echo "   ..."
    echo "  🔧 Running script 'install_pak.R'..."
    Rscript ${TEMP_DIR}/install_pak.R "${TEMP_DIR}/pkgs-to-install-using-pak.yml"
    echo "   ..."
    
    # Deactivate env
    deactivate_conda_env
fi
echo "..."

# Clean temporary files
clean_tmp_folder
echo "..."

# Final instructions
echo "====================================================="
echo "ℹ️  Conda env ${ENV_NAME} configured successfully!"
echo "ℹ️  To deactivate: 'conda deactivate'"
echo "ℹ️  To activate: 'conda activate $ENV_NAME'"
echo "ℹ️  To remove: 'conda env remove -n $ENV_NAME -y'"
echo "====================================================="