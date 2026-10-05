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
