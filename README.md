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
| **`apsim`** | R environment with apsimx, rapsimng, CroptimizR and Python SALib |

---

## 🚀 Quickstart

```bash
bash <(wget --no-cache -qO- https://raw.githubusercontent.com/luanabeckerdaluz/preconfigured-conda-envs/main/src/install.sh)
```

if you are running locally, please use the following command:

```bash
cd src/
install.sh --local
```

**📌 NOTE:**

- ✅ Linux
- 🚧 Windows: Not tested yet. This script will not run on **CMD/PowerShell**. Please, try to run using **Git Bash** or **WSL (Windows Subsystem for Linux)**.
- 🚧 macOS: Not tested yet. Please, install **wget** before running quickstart command.