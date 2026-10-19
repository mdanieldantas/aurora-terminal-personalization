# Compatibilidade Aurora

Alvo principal: Aurora Linux KDE/Aurora DX.

Não usar `apt`, `dnf`, `rpm-ostree` ou `sudo` para este projeto. Verifique o Homebrew e a disponibilidade real das ferramentas na sessão em que o script será executado.

A presença de uma ferramenta no Aurora CLI não garante automaticamente que ela esteja disponível fora do ambiente correspondente; o diagnóstico deve registrar o caminho encontrado.
