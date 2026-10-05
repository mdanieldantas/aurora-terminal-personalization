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
# aurora-terminal-personalization
