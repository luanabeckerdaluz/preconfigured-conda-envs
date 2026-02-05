#!/bin/bash

set -euo  # Interrompe em caso de erro

# Configurações
GITHUB_USERNAME=luanabeckerdaluz
GITHUB_REPO=conda-geo-rpy
GITHUB_BRANCH=main
ENV_NAME=""
LOCAL_ENV_NAME=""


#============================================================
# Validate input arguments
#============================================================

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Configura um ambiente Conda para APSIM a partir do repositório GitHub.

Opções:
  -n, --name NAME            (REQUIRED) Remote env name 
  -l, --local-name NAME      Local conda env name (Default: Remote env name)
  -h, --help                 Show help

Exemplos:
  $0 -n r-geo
  $0 -n r-geo -l my_local_r


  # Ver se o nome do conda pode ter - ou tem que ser _
  # Ver se o nome do conda pode ter - ou tem que ser _
  # Ver se o nome do conda pode ter - ou tem que ser _
  # Ver se o nome do conda pode ter - ou tem que ser _
  # Ver se o nome do conda pode ter - ou tem que ser _
  # Ver se o nome do conda pode ter - ou tem que ser _
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            ENV_NAME="$2"
            shift 2
            ;;
        -l|--local-name)
            LOCAL_ENV_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "❌ Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate variables
if [ -z "$ENV_NAME" ]; then
    echo "❌ Error: Env name (-n argument) is required!"
    exit 1
fi
if [[ ! "$ENV_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Erro: Nome do ambiente inválido: '$ENV_NAME'. Use apenas letras, números, hífens e underscores."
    exit 1
fi
if [[ ! "$LOCAL_ENV_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Erro: Nome do ambiente inválido: '$LOCAL_ENV_NAME'. Use apenas letras, números, hífens e underscores."
    exit 1
fi

#============================================================
# Check Conda installation
#============================================================

if ! command -v conda &> /dev/null; then
    echo "❌ Erro: Conda não encontrado. Instale o Anaconda/Miniconda primeiro."
    exit 1
fi


# ENV_FILE = ????
REPO_URL="https://raw.githubusercontent.com/${GITHUB_USERNAME}/${GITHUB_REPO}/${GITHUB_BRANCH}"
# echo "🔧 Configurando ambiente '${ENV_NAME}'..."
# ENV_URL="${REPO_URL}/${ENV_FILE}"





echo "📦 Configurando ambiente: $ENV_NAME"
echo "📁 Pasta no repositório: envs/$ENV_FOLDER"

# Lista de arquivos possíveis (environment.yml sempre primeiro)
FILES=(
    "environment.yml"
    "install.R"
)

download_if_exists() {
    local file="$1"
    local url="$REPO_URL/envs/$ENV_FOLDER/$file"
    
    # Verificar se o arquivo existe (cabeçalho HTTP 200)
    if curl -s -I "$url" 2>/dev/null | head -n 1 | grep -q "200 OK"; then
        echo "  ✓ Baixando $file..."
        curl -s -L -o "$file" "$url"
        return 0
    else
        echo "  ✗ $file não encontrado (pulando)"
        return 1
    fi
}

# Criar diretório temporário
TEMP_DIR="/tmp/conda_env_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo ""
echo "📥 Baixando arquivos..."

if ! download_if_exists "environment.yml"; then
    echo "❌ ERRO: environment.yml não encontrado em envs/$ENV_FOLDER/"
    echo "   Verifique se a pasta existe no repositório."
    rm -rf "$TEMP_DIR"
    exit 1
fi

for file in "${FILES[@]:1}"; do  # Pula o primeiro (environment.yml)
    download_if_exists "$file" || true
done





# #============================================================
# # Check if env already exists
# #============================================================

# echo "🔧 Verificando se o ambiente '${ENV_NAME}' já existe..."
# if conda env list | grep -q "^$ENV_NAME\s"; then
#     echo "❌ Erro: O ambiente '${ENV_NAME}' já existe! Por favor, remova ele ou defina outro nome para o seu ambiente."
#     exit 1
# fi

# #============================================================
# # Create environment
# #============================================================

# # Baixar o environment.yml do repositório
# echo "🔧 Baixando ${ENV_FILE}..."
# curl -s -L -o /tmp/environment.yml "${ENV_URL}"
# if [ ! -f /tmp/environment.yml ]; then
#     echo "❌ Erro: Não foi possível baixar o ou arquivo environment está inválido."
#     echo "URL tentada: ${ENV_URL}"
#     exit 1
# fi
# echo "✅ Arquivo ${ENV_FILE} baixado com sucesso!"

# # Criar ambiente a partir do arquivo
# echo "🔧 Criando ambiente '$ENV_NAME'"
# conda env create -f /tmp/environment.yml -n "$ENV_NAME"
# echo "✅ Ambiente '${ENV_NAME}' criado!"


# # # Função para ativar o ambiente (compatível com diferentes shells)
# # activate_env() {
# #     # Tenta diferentes métodos de ativação
# #     if [ -n "$BASH_VERSION" ]; then
# #         source "$(conda info --base)/etc/profile.d/conda.sh"
# #     elif [ -n "$ZSH_VERSION" ]; then
# #         source "$(conda info --base)/etc/profile.d/conda.sh"
# #     fi
# #     conda activate "$ENV_NAME"
# # }

# echo "🔧 Ativando ambiente..."
# source "$(conda info --base)/etc/profile.d/conda.sh"
# conda activate "$ENV_NAME"
# # Verificar se o ambiente foi ativado
# if [ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]; then
#     echo "Aviso: Ambiente não ativado automaticamente."
#     echo "Por favor, execute manualmente: conda activate $ENV_NAME"
#     exit 1
# else
#     echo "✅ Ambiente $ENV_NAME ativado com sucesso!"
# fi

# # Verificar instalação do R (se aplicável)
# if command -v R &> /dev/null; then
#     echo "🔧 Verificando instalação do R..."
#     R --version | head -n 1
    
#     # Instalar pacotes R adicionais se necessário
#     # (adicione aqui pacotes específicos)
# fi
# echo "✅ R está instalado!"

# echo "🔧 Desativando ambiente..."
# conda deactivate
# echo "✅ Ambiente desativado!"

# # Limpar arquivo temporário
# echo "🔧 Limpando arquivos temporários..."
# rm -f /tmp/environment.yml
# echo "✅ Arquivos temporários foram limpos!"

# echo "====================================================="
# echo "ℹ️  Ambiente ${ENV_NAME} configurado com sucesso!"
# echo "ℹ️  Para desativar: 'conda deactivate'"
# echo "ℹ️  Para ativar: 'conda activate $ENV_NAME'"
# echo "ℹ️  Para remover: 'conda env remove -n $ENV_NAME'"
# echo "====================================================="