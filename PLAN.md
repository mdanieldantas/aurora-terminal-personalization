# Plano do projeto

## Fase 1 — Estrutura e diagnóstico

- Estrutura inicial.
- Documentação básica.
- Diagnóstico sem efeitos colaterais.
- Validação Bash.

## Fase 2 — Dependências

- Detectar Aurora, Aurora DX, Aurora CLI e Homebrew.
- Comparar comandos disponíveis.
- Instalar somente ausentes via Homebrew, com confirmação.
- Incluir Yazi como componente opcional.

## Fase 3 — Backup e configuração

- Criar backup datado e manifesto.
- Copiar modelos para `~/.config/zsh/` somente após confirmação.
- Preservar arquivos não gerenciados.
- Validar Zsh antes de substituir qualquer arquivo.

## Fase 4 — Plugins e integração

- zsh-autosuggestions.
- fast-syntax-highlighting.
- zsh-history-substring-search.
- zsh-vi-mode opcional.
- Starship e Yazi.

## Fase 5 — Restauração e testes

- Restaurar por manifesto.
- Fazer backup antes de restaurar.
- Testar idempotência, simulação, sintaxe e falhas de rede.

## Limites

A ativação do Developer Mode, do Aurora CLI, do `dx-group` e a mudança do shell de login permanecem manuais.
