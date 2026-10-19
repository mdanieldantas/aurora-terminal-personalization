# Catálogo de aplicativos — Aurora Linux

Arquivo principal para importação no Notion: `catalogo-aplicativos-aurora-notion.csv`

## Importação no Notion
1. Crie ou abra uma página no Notion.
2. Use `Import` e selecione o arquivo CSV.
3. Configure `Nome` como título.
4. Transforme `Categoria`, `Método de instalação`, `Prioridade` e `Status` em Select.
5. Transforme `Site oficial` em URL.
6. Crie views filtradas por método e status.

## Views recomendadas
- Instalar agora: Prioridade = Essencial e Status diferente de Instalado.
- Por método: agrupar por Método de instalação.
- Por categoria: agrupar por Categoria.
- Pendências: Status = Pendente ou Decidir.
- Manuais: Método de instalação contém Manual.
- Controle: Status contém Não instalar automaticamente.

## Regras do projeto
- Ferramentas de terminal: Homebrew.
- Aplicativos gráficos: Flatpak quando disponível.
- AppImages: baixar manualmente, importar no Gear Lever e mover para `~/Applications/AppImages`.
- Serviços: container, quando necessário.
- Não instalar Docker, Podman, PostgreSQL ou MariaDB automaticamente.
- Não instalar driver NVIDIA proprietário neste momento.

Linhas: 73
Data de geração: 2026-10-06
