#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=0
CREATED=0
PRESERVED=0

usage() {
    cat <<'HELP'
Uso: bash tools/create-project-structure.sh [--dry-run | --help]

Coloque este script em tools/, dentro da pasta do projeto.
Cria somente diretórios e arquivos ausentes, sem instalar programas.
Não exige Git: funciona também com um repositório baixado como ZIP.
--dry-run mostra o que seria criado, sem escrever arquivos.
HELP
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Opção desconhecida: %s\n' "$arg" >&2; exit 1 ;;
    esac
done

if [[ "$(id -u)" -eq 0 ]]; then
    printf 'Execute como usuário comum, sem sudo.\n' >&2
    exit 1
fi

if [[ -L "${BASH_SOURCE[0]}" ]]; then
    printf 'Use o arquivo original, não um link simbólico.\n' >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ "${SCRIPT_DIR##*/}" != tools ]]; then
    printf 'Coloque o script na subpasta tools/ do projeto antes de executar.\n' >&2
    exit 1
fi
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

trap 'printf "Erro na linha %s. Nenhum arquivo existente foi substituído.\n" "$LINENO" >&2' ERR

printf 'Raiz do projeto: %s\n' "$PROJECT_ROOT"
if (( DRY_RUN )); then
    printf 'Modo simulação: nenhuma alteração será feita.\n'
fi

ensure_directory() {
    local relative="$1" path="$PROJECT_ROOT/$1"
    if [[ -L "$path" ]]; then
        printf 'Interrompido: diretório é um link simbólico: %s\n' "$relative" >&2
        exit 1
    elif [[ -d "$path" ]]; then
        printf '[PRESERVADO] Diretório: %s\n' "$relative"
    elif [[ -e "$path" ]]; then
        printf 'Interrompido: existe um arquivo no lugar do diretório: %s\n' "$relative" >&2
        exit 1
    elif (( DRY_RUN )); then
        printf '[SIMULAÇÃO] Criar diretório: %s\n' "$relative"
    else
        mkdir -- "$path"
        printf '[CRIADO] Diretório: %s\n' "$relative"
    fi
}

write_missing() {
    local relative="$1" path="$PROJECT_ROOT/$1"
    if [[ -L "$path" ]]; then
        printf 'Interrompido: arquivo é um link simbólico: %s\n' "$relative" >&2
        exit 1
    elif [[ -f "$path" ]]; then
        cat > /dev/null
        PRESERVED=$((PRESERVED + 1))
        printf '[PRESERVADO] Arquivo: %s\n' "$relative"
    elif [[ -e "$path" ]]; then
        printf 'Interrompido: destino não é um arquivo comum: %s\n' "$relative" >&2
        exit 1
    elif (( DRY_RUN )); then
        cat > /dev/null
        CREATED=$((CREATED + 1))
        printf '[SIMULAÇÃO] Criar arquivo: %s\n' "$relative"
    else
        (set -o noclobber; cat > "$path")
        CREATED=$((CREATED + 1))
        printf '[CRIADO] Arquivo: %s\n' "$relative"
    fi
}

# Pais antes dos filhos; não atravessar links simbólicos existentes.
for directory in config config/zsh config/starship docs tools logs backups tests; do
    ensure_directory "$directory"
done

write_missing README.md <<'EOF'
# Aurora Terminal Personalization

Projeto independente para personalizar o terminal do Aurora Linux.
Não é um instalador do Aurora e não é uma ferramenta oficial da distribuição.

## Estado atual

Somente a estrutura do projeto foi implementada.
O personalizador e o restaurador são marcadores seguros e não aplicam alterações.
Os arquivos de config/ são modelos pendentes de implementação.

## Preparar a estrutura

Depois de clonar o repositório ou extrair seu ZIP, execute na raiz:

    bash tools/create-project-structure.sh --dry-run
    bash tools/create-project-structure.sh

O criador preserva arquivos existentes e não precisa de Git.
Não instala ferramentas, não muda o shell e não altera configurações do usuário.

## Antes da futura personalização

Preparar manualmente o Aurora DX e o Aurora CLI; verificar o Homebrew.
Essas etapas não são realizadas pelo criador de estrutura.
A futura implementação deve identificar o ambiente real e evitar duplicações.

## Documentação

- PLAN.md: planejamento e critérios de segurança.
- docs/como-instalar.md: preparação e execução.
- docs/como-usar.md: organização dos arquivos.
- docs/restauracao.md: situação do recurso de restauração.

Logs e backups pessoais não devem ser publicados.
Revise o .gitignore antes de adicionar arquivos ao Git.
EOF

write_missing PLAN.md <<'EOF'
# Plano de implementação

## Etapa concluída

- Estrutura inicial com criação somente de arquivos ausentes.
- Personalizador e restaurador sem ações reais.

## Próximas etapas

1. Registrar o estado real do Aurora DX, Aurora CLI, Homebrew e shell.
2. Conferir executáveis e integrações no host e em eventuais contêineres.
3. Implementar diagnóstico e simulação antes de qualquer instalação.
4. Definir dependências opcionais pelo Homebrew, sem duplicar ferramentas.
5. Implementar backup com manifesto dos arquivos alterados e criados.
6. Implementar e testar restauração antes de aplicar configurações.
7. Configurar Zsh e Starship preservando personalizações existentes.
8. Integrar plugins Zsh com ordem de carregamento e teclas testadas.
9. Integrar Yazi e dependências opcionais de pré-visualização.
10. Validar sintaxe e testar sessão sem alterar o shell de login.

## Plugins previstos

- zsh-autosuggestions.
- fast-syntax-highlighting.
- zsh-history-substring-search.
- zsh-vi-mode, opcional.

## Segurança

- Sem ativação automática de Developer Mode ou Aurora CLI.
- Sem apt, dnf ou instalação de pacotes no sistema-base.
- Sem alteração automática do shell de login.
- Sem sobrescrever configurações sem backup e revisão.
- Simulação sem criar arquivos, logs ou baixar dependências.
- Nunca considerar a simples presença de um comando como prova de integração.
- Modelos não devem ser copiados para a configuração ativa nesta etapa.
EOF

write_missing .gitignore <<'EOF'
# Dados pessoais e artefatos locais
/logs/*
!/logs/.gitkeep
/backups/*
!/backups/.gitkeep
/.cache/
*.tmp
*.bak
EOF

write_missing personalize-aurora-terminal.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' \
    'Personalizador ainda não implementado.' \
    'Nenhuma ferramenta foi instalada e nenhuma configuração foi alterada.'
exit 0
EOF

write_missing restore-aurora-terminal.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' \
    'Restaurador ainda não implementado.' \
    'Nenhum arquivo foi restaurado ou alterado.'
exit 0
EOF

write_missing Brewfile <<'EOF'
# Dependências serão definidas após o diagnóstico do ambiente.
# Nenhuma fórmula está habilitada nesta versão.
# Yazi será um componente opcional da personalização.
EOF

for name in .zshenv .zshrc aliases.zsh plugins.zsh bindings.zsh yazi.zsh; do
    write_missing "config/zsh/$name" <<'EOF'
# Modelo pendente de implementação.
# Não copiar para a configuração ativa do usuário nesta etapa.
EOF
done

write_missing config/starship/starship.toml <<'EOF'
# Modelo pendente de implementação.
# Nenhuma personalização do Starship foi definida nesta etapa.
EOF

write_missing docs/como-instalar.md <<'EOF'
# Preparação do projeto

1. Crie ou baixe a pasta aurora-terminal-personalization.
2. Coloque o criador em tools/create-project-structure.sh.
3. Na raiz, execute: bash tools/create-project-structure.sh --dry-run
4. Confira a raiz exibida e as ações planejadas.
5. Execute: bash tools/create-project-structure.sh

Não use sudo. Não é necessário tornar o script executável ao usar bash.
O nome da pasta raiz pode mudar; sua localização é calculada a partir de tools/.
Git não é obrigatório, inclusive quando o projeto é baixado como ZIP.

O criador não reinstala arquivos existentes, nem atualiza seu conteúdo.
Se README.md ou .gitignore já existirem, revise-os manualmente.
A personalização real ainda não está disponível.
EOF

write_missing docs/como-usar.md <<'EOF'
# Organização

- tools/: ferramentas de preparação do projeto.
- config/: modelos, separados da configuração ativa do usuário.
- docs/: documentação.
- logs/: registros locais das futuras execuções.
- backups/: cópias locais das futuras configurações anteriores.
- tests/: testes do projeto.
- Brewfile: futuras dependências gerenciadas pelo Homebrew.

Executar o criador novamente preserva o conteúdo dos arquivos existentes.
Ele pode deixar uma estrutura parcial caso encontre um erro; não desfaz arquivos criados.
Após corrigir a causa, execute novamente para criar o que ainda estiver ausente.
Não mova modelos para ~/.config ou para ~/.zshenv nesta etapa.
EOF

write_missing docs/restauracao.md <<'EOF'
# Restauração

Recurso ainda não implementado.
A pasta backups/ é apenas uma reserva de espaço na estrutura.
O script restore-aurora-terminal.sh não restaura arquivos nesta versão.
Antes da personalização real, serão implementados backup, manifesto e testes.
Backups podem conter dados pessoais e não devem ser publicados.
EOF

write_missing tests/README.md <<'EOF'
# Testes planejados

- Sintaxe Bash dos scripts.
- Simulação sem escrita de arquivos.
- Segunda execução preservando os arquivos existentes.
- Uso em caminhos com espaços.
- Uso sem diretório .git, incluindo download ZIP.
- Recusa de destinos que sejam links simbólicos.
- Backup e restauração antes da aplicação real.
EOF

write_missing logs/.gitkeep < /dev/null
write_missing backups/.gitkeep < /dev/null

printf '\nArquivos %s: %s; arquivos existentes preservados: %s\n' \
    "$([[ "$DRY_RUN" -eq 1 ]] && printf previstos || printf criados)" \
    "$CREATED" "$PRESERVED"
printf 'Nenhuma personalização do terminal foi aplicada.\n'
printf 'Revise .gitignore antes de publicar logs ou backups.\n'
