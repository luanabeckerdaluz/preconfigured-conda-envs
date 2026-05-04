#!/usr/bin/env python3

import os
import re
import sys
import subprocess
import tempfile
import shutil
import urllib.request
from typing import List, Optional

VERSION = "1.0.12"

# GitHub configs
GITHUB_USER = "luanabeckerdaluz"
GITHUB_REPO = "preconfigured-conda-envs"
GITHUB_BRANCH = "main"

# Available files
ENV_AVAILABLE_FILES = ["environment.yml", "pkgs-to-install-using-pak.yml", "pkgs-to-install-from-source.yml"]

# Tools scripts
TOOL_AVAILABLE_SCRIPTS = ["install_pak.R", "install_source.R"]

# Available environments
ENV_NAMES = ["local", "r-geo", "py-geo", "apsim-v1", "apsim-debian-bullseye"]

class CondaEnvInstaller:
    """Pre-configured conda envs installer"""
    
    def __init__(self):
        self.use_local = False
        self.local_path = None
        self.temp_dir = None
        self.env_name = None
        self.remote_env_name = None
        self.register_jupyter_kernels = False
        
    def error_message(self, msg: str) -> None:
        """Print error message"""
        print(f"❌ ERROR: {msg}!")
        
    def abort_installation(self) -> None:
        """Abort installation"""
        self.error_message("Aborting installation")
        self.clean_temp_folder()
        sys.exit(0)
    
    def clean_temp_folder(self) -> None:
        """Clean temporary folder"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            print(f"🧹 Cleaning temporary folder '{self.temp_dir}...")
            shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def run_command(self, cmd: List[str], capture_output: bool = False, check: bool = True) -> Optional[str]:
        """Run command and return output if necessary"""
        print(f"  🔧 Running: {' '.join(cmd)}")
        try:
            if capture_output:
                result = subprocess.run(cmd, capture_output=True, text=True, check=check)
                return result.stdout.strip()
            else:
                subprocess.run(cmd, check=check)
                return None
        except subprocess.CalledProcessError as e:
            if check:
                self.error_message(e)
                raise
            return None
    
    def retrieve_without_cache(self, url: str, output_path: str) -> bool:
        """Download remote file"""
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
    
    def retrieve_file(self, github_env_path_from_root_or_localpath: str, filename: str, dest_dir: str, use_local = False) -> bool:
        """Retrieve file (Copy local ou download remote)"""
        dest_path = os.path.join(dest_dir, filename)
        
        if use_local:
            source_path = os.path.join(github_env_path_from_root_or_localpath, filename)
            try:
                shutil.copy2(source_path, dest_path)
                print(f"  📥 Copied {filename} from folder {github_env_path_from_root_or_localpath} to folder {dest_dir}...")
                return True
            except FileNotFoundError:
                return False
        else:
            url = f"https://raw.githubusercontent.com/{GITHUB_USER}/{GITHUB_REPO}/{GITHUB_BRANCH}/{github_env_path_from_root_or_localpath}/{filename}"
            print(f"  📥 Downloading {filename} into folder {dest_dir}...")
            return self.retrieve_without_cache(url, dest_path)
    
    def check_conda_installation(self) -> None:
        """Check if conda is installed"""
        if shutil.which("conda") is None:
            self.error_message("Conda not found. Please, install miniconda from 'https://www.anaconda.com/docs/getting-started/miniconda'")
            self.abort_installation()
        print("✅ Conda found!")
    
    def check_r_installation(self) -> bool:
        """Check if R is installed inside created conda env"""
        print("  🔧 Checking R installation...")
        
        # Use conda run to check R version
        try:
            result = subprocess.run(
                ["conda", "run", "-n", self.env_name, "R", "--version"],
                capture_output=True, text=True, check=True
            )
            r_version = result.stdout.split('\n')[0] if result.stdout else "R installed"
            return True
        except subprocess.CalledProcessError:
            return False

    def check_python_installed(self) -> bool:
        """Check if Python is installed inside created conda env"""
        print("  🔧 Checking Python installation...")
        
        # Use conda run to check R version
        try:
            self.run_command(
                ["conda", "run", "-n", self.env_name, "python", "--version"],
                capture_output=True,
                check=True
            )
            return True
        except subprocess.CalledProcessError:
            return False

    def register_kernels(self) -> None:
        """Register Python and R kernels in Jupyter for the conda environment"""
        print("🔧 Registering Jupyter kernels...")
        
        # Register Python kernel only if Python and ipykernel are available
        if self.check_python_installed():
            # Get conda prefix path
            conda_base = self.run_command(["conda", "info", "--base"], capture_output=True)
            conda_prefix = os.path.join(conda_base.strip(), "envs", self.env_name)
            
            python_kernel_name = self.env_name
            python_display_name = f"Python ({self.env_name})"
            
            print(f"  📝 Registering Python kernel: {python_kernel_name}...")
            try:
                self.run_command([
                    "conda", "run", "-n", self.env_name,
                    "python", "-m", "ipykernel", "install",
                    "--name", python_kernel_name,
                    "--prefix", conda_prefix,
                    "--display-name", python_display_name
                ])
            except subprocess.CalledProcessError:
                self.error_message("ipykernel is not installed in the conda environment. Please add it to the environment.yml file or contact support.")
                self.abort_installation()

            print(f"  ✅ Python kernel: {python_kernel_name} was registered successfully!")
        
        # Register R kernel only if R and IRkernel are available
        if self.check_r_installation():
            r_kernel_name = f"{self.env_name}"
            r_display_name = f"R ({self.env_name})"
            
            print(f"  📝 Registering R kernel: {r_display_name}...")
            try:
                self.run_command([
                    "conda", "run", "-n", self.env_name,
                    "Rscript", "-e",
                    f"IRkernel::installspec(name='{r_kernel_name}', displayname='{r_display_name}')"
                ])
            except subprocess.CalledProcessError:
                self.error_message("IRkernel is not installed in the conda environment. Please add it to the R packages or contact support.")
                self.abort_installation()

            print(f"  ✅ R kernel: {r_kernel_name} was registered successfully!")
    
    def check_env_exists(self, env_name: str) -> bool:
        """Check if conda env to be installed already exists"""
        result = self.run_command(["conda", "env", "list"], capture_output=True, check=False)
        
        pattern = re.compile(rf"^{env_name}\s")
        
        for line in result.split('\n'):
            if pattern.search(line):
                return True
        return False
    
    def create_environment(self, env_name: str, yaml_path: str) -> None:
        """Create conda env from yaml file"""
        print(f"🔧 Creating env '{env_name}'...")
        self.run_command(["conda", "env", "create", "-f", yaml_path, "-n", env_name])
        
        # Check if environment was created successfully
        if self.check_env_exists(env_name):
            print(f"✅ Conda env '{env_name}' was created successfully!")
        else:
            self.error_message(f"Could not create Conda environment '{env_name}'")
            self.abort_installation()
    
    def install_r_packages(self, temp_dir: str) -> None:
        """Install R packages if necessary using conda run"""
        print("🔧 This env requires R packages installation. I will activate the env and install the packages!")
        
        # Install R packages from source (pkgs-to-install-from-source.yml)
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
        
        # Install R packages using pak (pkgs-to-install-using-pak.yml)
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

    def validate_local_env_folder(self, path: str) -> None:
        """Check if folder contains exactly the required files"""
        if not os.path.isdir(path):
            self.error_message(f"Not a directory: {path}. Use as example the current directory: {os.getcwd()}")
            self.abort_installation()
        
        files = {f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))}
        
        # Check 1: Must have environment.yml
        if "environment.yml" not in files:
            self.error_message("Missing required file: environment.yml")
            self.abort_installation()

        # Check 2: All files must be in ENV_AVAILABLE_FILES (no unexpected files)
        unexpected = [f for f in files if f not in ENV_AVAILABLE_FILES]
        if unexpected:
            self.error_message(f"Unexpected file(s) found. Please remove the following files or move to a subfolder: {unexpected}")
            self.abort_installation()

    def select_environment(self) -> None:
        """Initial menu to select environment"""
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
            
            # Check if choice is out of bounds
            idx = int(choice) - 1
            if idx < 0 or idx >= len(ENV_NAMES):
                self.abort_installation()
            
            self.remote_env_name = ENV_NAMES[idx]
            self.env_name = self.remote_env_name
            
            # Confirm
            confirm = input(f"❓ You chose '{self.env_name}'. Confirm installation? (y/n): ").strip().lower()
            if confirm not in ['y', 'yes', '']:
                self.abort_installation()

            # If env is local, get local path where env is located
            if self.env_name == "local":
                # Use local
                self.use_local = True
                # Ask local folder path and then filter string
                local_path = input(f"❓ Local folder path: (example: /home/jovyan/myenv): ").strip()
                local_path = local_path.strip('"').strip("'")
                local_path = os.path.expanduser(local_path)
                # Validate folder files
                self.validate_local_env_folder(local_path)
                self.local_path = local_path

            # Verify personalized env name
            new_name = input(f"❓ Name your conda env (default: '{self.env_name}'): ").strip()
            if new_name:
                # Validate env name
                if any(c in new_name for c in ['/', ':', '#', ' ']) or new_name in ['base', 'root']:
                    self.error_message("Invalid environment name! Cannot be empty or contain / : # ' ' or be 'base'/'root'")
                    self.abort_installation()
                
                confirm = input(f"❓ You named your conda env as '{new_name}'. Confirm? (y/n): ").strip().lower()
                if confirm in ['y', 'yes', '']:
                    self.env_name = new_name

            # Register kernels if necessary
            register_kernels = input(f"❓ Register Jupyter kernels for env '{self.env_name}'? (y/n): ").strip().lower()
            if register_kernels in ['y', 'yes', '']:
                self.register_jupyter_kernels = True
                    
        except KeyboardInterrupt:
            print("\n")
            self.abort_installation()
    
    def run(self) -> None:
        """main installation flow"""
        
        # Check pre requirements
        self.check_conda_installation()
        
        # User select environment
        self.select_environment()
        
        # Check if env name already exists
        if self.check_env_exists(self.env_name):
            self.error_message(f"Conda environment '{self.env_name}' already exists! Please, remove it manually before continue using 'conda env remove --name {self.env_name} -y'")
            self.abort_installation()
        
        # Create temporary folder
        self.temp_dir = tempfile.mkdtemp(prefix="conda_env_")
        print(f"📁 Created temporary folder: {self.temp_dir}")
        
        try:
            print("📥 Retrieving or copy env files and tool scripts...")
            github_env_path_from_root_or_localpath = self.local_path if self.use_local else f"envs/{self.remote_env_name}"
            
            # Retrieve or copy environment.yml (required)
            if not self.retrieve_file(
                github_env_path_from_root_or_localpath = github_env_path_from_root_or_localpath,
                filename = "environment.yml",
                dest_dir = self.temp_dir,
                use_local = self.use_local
                ):
                self.error_message("environment.yml file not found. Please, contact support")
                self.abort_installation()
            
            # Retrieve or copy other optional env files
            for filename in ENV_AVAILABLE_FILES[1:]:
                self.retrieve_file(
                    github_env_path_from_root_or_localpath = github_env_path_from_root_or_localpath, filename = filename, 
                    dest_dir = self.temp_dir, 
                    use_local = self.use_local
                )
            
            # Download tool scripts
            for filename in TOOL_AVAILABLE_SCRIPTS:
                self.retrieve_file(
                    github_env_path_from_root_or_localpath = "src", 
                    filename = filename, 
                    dest_dir = self.temp_dir,
                    use_local=False
                )
            
            print("✅ Env files and tool scripts retrieved successfully!")
            print("...")
            
            # Create conda environment
            self.create_environment(
                self.env_name,
                os.path.join(self.temp_dir, "environment.yml")
            )

            # Check if R files are available for this env. If so, install R packages.
            has_r_packages = (
                os.path.exists(os.path.join(self.temp_dir, "pkgs-to-install-using-pak.yml")) or
                os.path.exists(os.path.join(self.temp_dir, "pkgs-to-install-from-source.yml"))
            )
            if has_r_packages:
                if not self.check_r_installation():
                    self.error_message("R is not installed in the conda environment")
                    self.abort_installation()
                # If R is installed, install R packages                    
                print("  ✅ R is installed in the conda environment!")
                self.install_r_packages(self.temp_dir)
            
            print("...")

            # Register Jupyter Kernels if necessary
            if self.register_jupyter_kernels:
                self.register_kernels()
            
            print("...")
            print("=" * 50)
            print(f"ℹ️  Conda env {self.env_name} configured successfully!")
            print(f"ℹ️  To activate: 'conda activate {self.env_name}'")
            print(f"ℹ️  To install conda packages: 'conda install -c conda-forge <package>...'")
            print(f"ℹ️  To install Python pip packages: 'pip install ...'")
            print(f"ℹ️  To install R packages: 'Rscript -e \"install.packages(...)\"'")
            print(f"ℹ️  To deactivate: 'conda deactivate'")
            print(f"ℹ️  To remove: 'conda env remove -n {self.env_name} -y'")
            print("=" * 50)
            
        finally:
            self.clean_temp_folder()


def main():
    """Function to handle arguments"""
    # Process arguments
    args = sys.argv[1:]
    for arg in sys.argv[1:]:
        if arg in ['-v', '--version']:
            print(f"preconfigured-conda-envs | Version: {VERSION}")
            sys.exit(0)
        else:
            print(f"❌ ERROR: Invalid parameter '{arg}'! Available parameter are only --version")
            sys.exit(1)

    installer = CondaEnvInstaller()
    installer.run()


if __name__ == "__main__":
    main()