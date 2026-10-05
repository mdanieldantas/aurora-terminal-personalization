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
