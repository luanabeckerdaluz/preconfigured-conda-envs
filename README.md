# Conda preconfigured environments

**One command. Full Conda environment!**

Setting up computational environments for scientific work often involves complex, error-prone manual steps — particularly when integrating R, Python, and system-level geospatial libraries. **This tool automates the process of creating pre-configured Conda environments, ensuring consistency across installations and eliminating hidden configuration issues.**

**Choose the environment you need and a single terminal command does everything!**

---

## 📦 Available environments

| Environment | Description |
|-------------|-------------|
| **`r-geo`** | R with tidyverse, sf, terra, raster, and geospatial analysis packages |
| **`py-geo`** | Python with geopandas, shapely, rasterio, pyproj and geospatial analysis packages |
| **`apsim-v1`** | R environment with apsimx, rapsimng, CroptimizR and Python SALib |
| **`apsim-debian-bullseye`** | Specific environment installing R packages from source |

---

## 🔧 Pre requisites

This script requires Conda and Python commands. Thus, you can install miniconda:

- 🪟 Windows: https://www.anaconda.com/docs/getting-started/miniconda/install/windows-gui-install
- 🐧 Linux: https://www.anaconda.com/docs/getting-started/miniconda/install#linux-terminal-installer
- 🍎 macOS: ??????????????
??????????????
??????????????
??????????????
??????????????


## 🚀 Quickstart

### 🪟 Windows

Run the following command inside `Anaconda Prompt`, which has access to `conda` and `python` commands:

```bash
bash <(wget -qO- "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/install.sh?$(date +%s)")
```

### 🐧 Linux

Run the following command inside any terminal which has access to `conda` and `python` commands:

```bash
python3 -i <(curl -sSL "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/test_main.py") "$@"

or

bash <(wget -qO- "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/install.sh?$(date +%s)")
```

### 🍎 macOS

🚧 Not tested yet! 🚧 Maybe you can run using the following command:

```bash
python3 -i <(curl -sSL "https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/test_main.py") "$@"
```