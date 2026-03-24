# Conda preconfigured environments

**One command. Full pre-configured conda environment!**

Setting up computational environments for scientific work often involves complex, error-prone manual steps — particularly when integrating R, Python, and system-level geospatial libraries. **This tool automates the process of creating pre-configured Conda environments, ensuring consistency across installations and eliminating hidden configuration issues.**

**Choose the environment you need and a single terminal command does everything!**

---

## 📦 Available environments

| Environment | Description |
|-------------|-------------|
| **`r-geo`** | R environment with important packages for geospatial processing, such as tidyverse, sf, terra, raster |
| **`py-geo`** | Python environment with important packages for geospatial processing, such as geopandas, shapely, rasterio, pyproj |
| **`apsim-v1`** | R environment with important packages for running APSIMx simulations and performing sensitivity analysis, such as apsimx, rapsimx, CroptimizR and Python SALib |
| **`apsim-debian-bullseye`** | Specific environment installing R packages from source |
| **`⚠️ local`** | You specify a local folder from your computer where env files are located |

---

## 🔧 Pre requisites

This script requires Conda and Python commands. Thus, you can install miniconda:

- 🪟 Windows: https://www.anaconda.com/docs/getting-started/miniconda/install/windows-gui-install
- 🐧 Linux: https://www.anaconda.com/docs/getting-started/miniconda/install#linux-terminal-installer
- 🍎 macOS: https://docs.conda.io/projects/conda/en/stable/user-guide/install/macos.html

---

## 🚀 Quickstart

### 🐧 Linux

Run the following command inside any terminal which has access to `conda` and `python` commands:

```bash
python3 -i <(curl -sSL "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/main.py") "$@"
```

### 🪟 Windows

Run the following command inside `Anaconda Prompt`, which has access to `conda` and `python` commands:

```bash
# Powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/main.py" -OutFile "$env:TEMP\main.py"
python3 "$env:TEMP\main.py"

# WLS
wsl python3 -i <(curl -sSL "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/main.py") "$@"

# Git Bash
python3 -i <(curl -sSL "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/main.py") "$@"
```

### 🍎 macOS

🚧 Not tested yet! 🚧 Maybe you can run using the same command as above Linux section!

---

## 🔧 Creating your own env folder

You can create your own env folder. To do this, you can simply copy one of the envs folders from this repository, edit and test with your own packages specifications (when running tool, select `local` option).

When creating a new env, you can set the following files. `environment.yml`is the only one required.

- `environment.yml`: Conda environment file that defines the complete development environment, including system-level dependencies (compilers, libraries, and external tools).
- `pkgs-to-install-from-source.yml`: List of R packages that must be compiled from source.
- `pkgs-to-install-using-pak.yml`: List of R packages installed via the pak package manager, typically pulling pre-compiled binaries from CRAN or GitHub.

Feel free to contribute to this repository (pull request) with your custom env!
