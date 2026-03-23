#!/usr/bin/env python3
"""
Script para instalação de ambientes conda pré-configurados
Equivalente em Python ao script bash original
"""

import os
import re
import sys
import subprocess
import tempfile
import shutil
import urllib.request
from pathlib import Path
from typing import List, Optional, Tuple

VERSION = "1.0.10"

# Configurações do GitHub
GITHUB_USER = "luanabeckerdaluz"
GITHUB_REPO = "preconfigured-conda-envs"
GITHUB_BRANCH = "main"

# Arquivos de ambiente disponíveis
ENV_AVAILABLE_FILES = ["environment.yml", "pkgs-to-install-using-pak.yml", "pkgs-to-install-from-source.yml"]

# Scripts de ferramentas
TOOL_AVAILABLE_SCRIPTS = ["install_pak.R", "install_source.R"]

# Ambientes disponíveis
ENV_NAMES = ["r-geo", "py-geo", "apsim-v1", "apsim-debian-bullseye"]


class CondaEnvInstaller:
    """Instalador de ambientes conda pré-configurados"""
    
    def __init__(self, use_local=False):
        self.use_local = use_local
        self.temp_dir = None
        self.env_name = None
        self.remote_env_name = None
        
    def error_message(self, msg: str) -> None:
        """Exibe mensagem de erro"""
        print(f"❌ ERROR: {msg}!")
        
    def abort_installation(self) -> None:
        """Aborta a instalação"""
        self.error_message("Aborting installation")
        self.clean_temp_folder()
        sys.exit(0)
    
    def clean_temp_folder(self) -> None:
        """Limpa pasta temporária"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            print(f"🧹 Cleaning temporary folder '{self.temp_dir}...")
            shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def run_command(self, cmd: List[str], capture_output: bool = False, check: bool = True) -> Optional[str]:
        """Executa comando e retorna saída se necessário"""
        print(f"  🔧 Executando: {' '.join(cmd)}")
        try:
            if capture_output:
                result = subprocess.run(cmd, capture_output=True, text=True, check=check)
                return result.stdout.strip()
            else:
                subprocess.run(cmd, check=check)
                return None
        except subprocess.CalledProcessError as e:
            if check:
                print(f"  ❌ Erro: {e}")
                raise
            return None
    
    def curl_without_cache(self, url: str, output_path: str) -> bool:
        """Download de arquivo com curl (sem cache)"""
        try:
            req = urllib.request.Request(
                url,
                headers={
                    'Cache-Control': 'no-cache, no-store, must-revalidate',
                    'Pragma': 'no-cache'
                }
            )
            with urllib.request.urlopen(req) as response:
                if response.status == 200:
                    with open(output_path, 'wb') as f:
                        f.write(response.read())
                    return True
            return False
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return False
            raise
    
    def retrieve_file(self, env_path_from_root: str, filename: str, dest_dir: str) -> bool:
        """Recupera arquivo (local ou remoto)"""
        dest_path = os.path.join(dest_dir, filename)
        
        if self.use_local:
            print(f"  📥 Copying {filename} to folder {dest_dir}...")
            source_path = os.path.join("..", env_path_from_root, filename)
            try:
                shutil.copy2(source_path, dest_path)
                return True
            except FileNotFoundError:
                return False
        else:
            url = f"https://raw.githubusercontent.com/{GITHUB_USER}/{GITHUB_REPO}/{GITHUB_BRANCH}/{env_path_from_root}/{filename}"
            print(f"  📥 Downloading {filename} into folder {dest_dir}...")
            return self.curl_without_cache(url, dest_path)
    
    def check_conda_installation(self) -> None:
        """Verifica se conda está instalado"""
        if shutil.which("conda") is None:
            self.error_message("Conda not found. Please, install miniconda from 'https://www.anaconda.com/docs/getting-started/miniconda'")
            self.abort_installation()
        print("✅ Conda found!")
    
    def check_curl_installation(self) -> None:
        """Verifica se curl está instalado"""
        if shutil.which("curl") is None:
            self.error_message("curl not found. Please, install curl from apt or conda")
            self.abort_installation()
        print("✅ curl found!")
    
    def check_r_installation(self) -> None:
        """Verifica se R está instalado no ambiente conda"""
        print("  🔧 Checking R installation...")
        
        # Usar conda run para verificar R no ambiente correto
        try:
            result = subprocess.run(
                ["conda", "run", "-n", self.env_name, "R", "--version"],
                capture_output=True, text=True, check=True
            )
            r_version = result.stdout.split('\n')[0] if result.stdout else "R installed"
            print(f"  {r_version}")
            print("  ✅ R is installed in the conda environment!")
        except subprocess.CalledProcessError:
            self.error_message("R is not installed in the conda environment")
            self.abort_installation()
    
    def check_env_exists(self, env_name: str) -> bool:
        """Verifica se ambiente conda já existe"""
        result = self.run_command(["conda", "env", "list"], capture_output=True, check=False)
        # Regex: ^env_name\s (início da linha, nome do env, espaço ou tab)
        
        pattern = re.compile(rf"^{env_name}\s")
        
        for line in result.split('\n'):
            if pattern.search(line):
                return True
        return False
    
    def create_environment(self, env_name: str, yaml_path: str) -> None:
        """Cria ambiente conda a partir do arquivo YAML"""
        print(f"🔧 Creating env '{env_name}'...")
        self.run_command(["conda", "env", "create", "-f", yaml_path, "-n", env_name])
        
        # Verificar se foi criado
        if self.check_env_exists(env_name):
            print(f"✅ Conda env '{env_name}' was created successfully!")
        else:
            self.error_message(f"Could not create Conda environment '{env_name}'")
            self.abort_installation()
    
    def activate_conda_env(self, env_name: str) -> None:
        """Ativa o ambiente conda (via conda run)"""
        print(f"  🔧 Activating '{env_name}' conda env...")
        
        # Verificar se o ambiente existe
        if not self.check_env_exists(env_name):
            self.error_message(f"Environment '{env_name}' does not exist")
            self.abort_installation()
        
        # Configurar variáveis de ambiente
        conda_base = self.run_command(["conda", "info", "--base"], capture_output=True)
        conda_prefix = os.path.join(conda_base, "envs", env_name)
        
        # Configurar LD_LIBRARY_PATH e PKG_CONFIG_PATH
        self.run_command(["conda", "env", "config", "vars", "set", 
                         f"LD_LIBRARY_PATH={conda_prefix}/lib",
                         f"PKG_CONFIG_PATH={conda_prefix}/lib/pkgconfig",
                         "-n", env_name])
    
    def install_r_packages(self, temp_dir: str) -> None:
        """Instala pacotes R necessários usando conda run"""
        print("🔧 This env requires R packages installation. I will activate the env and install the packages!")
        
        # Instalar pkgs-to-install-from-source.yml
        source_file = os.path.join(temp_dir, "pkgs-to-install-from-source.yml")
        if os.path.exists(source_file):
            print("  🔧 This env contains a 'pkgs-to-install-from-source.yml' file. These packages will be installed from source using install.packages() function.")
            print("  🔧 Running script 'install_source.R'...")
            self.run_command([
                "conda", "run", "-n", self.env_name,
                "Rscript", os.path.join(temp_dir, "install_source.R"),
                source_file
            ])
            print("   ...")
        
        # Instalar pkgs-to-install-using-pak.yml
        pak_file = os.path.join(temp_dir, "pkgs-to-install-using-pak.yml")
        if os.path.exists(pak_file):
            print("  🔧 This env contains a 'pkgs-to-install-using-pak.yml' file. These packages will be installed using pak package.")
            print("  🔧 Running script 'install_pak.R'...")
            self.run_command([
                "conda", "run", "-n", self.env_name,
                "Rscript", os.path.join(temp_dir, "install_pak.R"),
                pak_file
            ])
            print("   ...")
    
    def select_environment(self) -> None:
        """Menu de seleção de ambiente"""
        print("-" * 41)
        print(f"preconfigured-conda-envs | Version: {VERSION}")
        print("-" * 41)
        print("Select the environment you want to install:")
        print("")
        
        for i, env in enumerate(ENV_NAMES, 1):
            print(f"  {i}) {env}")
        print("")
        
        try:
            choice = input("❓ Insert option: ").strip()
            if not choice.isdigit():
                self.abort_installation()
            
            idx = int(choice) - 1
            if idx < 0 or idx >= len(ENV_NAMES):
                self.abort_installation()
            
            self.remote_env_name = ENV_NAMES[idx]
            self.env_name = self.remote_env_name
            
            # Confirmar
            confirm = input(f"❓ You chose '{self.env_name}'. Confirm installation? (y/n): ").strip().lower()
            if confirm not in ['y', 'yes', '']:
                self.abort_installation()
            
            # Verificar nome personalizado
            new_name = input(f"❓ Name your conda env (default: '{self.env_name}'): ").strip()
            if new_name:
                # Validar nome
                if any(c in new_name for c in ['/', ':', '#', ' ']) or new_name in ['base', 'root']:
                    self.error_message("Invalid environment name! Cannot be empty or contain / : # ' ' or be 'base'/'root'")
                    self.abort_installation()
                
                confirm = input(f"❓ You named your conda env as '{new_name}'. Confirm? (y/n): ").strip().lower()
                if confirm in ['y', 'yes', '']:
                    self.env_name = new_name
                    
        except KeyboardInterrupt:
            print("\n")
            self.abort_installation()
    
    def run(self) -> None:
        """Executa o fluxo principal de instalação"""
        
        # Verificar pré-requisitos
        self.check_conda_installation()
        
        # curl é opcional para modo local
        if not self.use_local:
            self.check_curl_installation()
        
        # Selecionar ambiente
        self.select_environment()
        
        # Verificar se ambiente já existe
        if self.check_env_exists(self.env_name):
            self.error_message(f"Conda environment '{self.env_name}' already exists! Please, remove it manually before continue using 'conda env remove --name {self.env_name} -y'")
            self.abort_installation()
        
        # Criar pasta temporária
        self.temp_dir = tempfile.mkdtemp(prefix="conda_env_")
        print(f"📁 Created temporary folder: {self.temp_dir}")
        
        try:
            # Recuperar arquivos
            print("📥 Retrieving env files and tool scripts...")
            
            env_dir = f"envs/{self.remote_env_name}"
            
            # environment.yml (obrigatório)
            if not self.retrieve_file(env_dir, "environment.yml", self.temp_dir):
                self.error_message("environment.yml file not found. Please, contact support")
                self.abort_installation()
            
            # Outros arquivos de ambiente (opcionais)
            for filename in ENV_AVAILABLE_FILES[1:]:
                self.retrieve_file(env_dir, filename, self.temp_dir)
            
            # Scripts de ferramentas (opcionais)
            for filename in TOOL_AVAILABLE_SCRIPTS:
                self.retrieve_file("src", filename, self.temp_dir)
            
            print("✅ Env files and tool scripts retrieved successfully!")
            print("...")
            
            # Criar ambiente
            self.create_environment(
                self.env_name,
                os.path.join(self.temp_dir, "environment.yml")
            )

            # Verificar se há pacotes R para instalar
            has_r_packages = (
                os.path.exists(os.path.join(self.temp_dir, "pkgs-to-install-using-pak.yml")) or
                os.path.exists(os.path.join(self.temp_dir, "pkgs-to-install-from-source.yml"))
            )
            
            if has_r_packages:
                self.check_r_installation()
                self.install_r_packages(self.temp_dir)
            
            print("...")
            
            # Finalização
            print("=" * 53)
            print(f"ℹ️  Conda env {self.env_name} configured successfully!")
            print(f"ℹ️  To deactivate: 'conda deactivate'")
            print(f"ℹ️  To activate: 'conda activate {self.env_name}'")
            print(f"ℹ️  To remove: 'conda env remove -n {self.env_name} -y'")
            print("=" * 53)
            
        finally:
            self.clean_temp_folder()


def main():
    """Função principal"""
    use_local = False
    
    # Processar argumentos
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg in ['-l', '--local']:
            use_local = True
            print("🔧 Installing Using local files...")
        elif arg in ['-v', '--version']:
            print(f"preconfigured-conda-envs | Version: {VERSION}")
            sys.exit(0)
        else:
            print(f"❌ ERROR: Invalid parameter '{arg}'! Available parameters are --local and --version")
            sys.exit(1)
        i += 1
    
    installer = CondaEnvInstaller(use_local=use_local)
    installer.run()


if __name__ == "__main__":
    main()