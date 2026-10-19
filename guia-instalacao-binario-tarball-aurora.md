# Instalar aplicativos por binário/tarball no Aurora

Este guia é para instalar programas distribuídos como `.tar.gz`, `.tar.xz` ou binário solto — como o Google Antigravity — **sem alterar a imagem do Aurora**.

A instalação fica no seu diretório pessoal, não exige `sudo` e pode ser removida apagando a pasta.

## Antes de começar

### 1. Confirme a arquitetura

```bash
uname -m
```

**O que faz:** mostra a arquitetura do processador.

| Saída | Arquivo que você deve baixar |
|---|---|
| `x86_64` | Linux x64 / amd64 |
| `aarch64` | Linux ARM64 / aarch64 |

### 2. Escolha a pasta de instalação

Recomendo usar:

```text
~/.local/opt/NOME-DO-APP
```

- `~` = sua pasta pessoal, por exemplo `/home/dan`
- `.local` = pasta oculta para dados e programas do usuário
- `opt` = local tradicional para aplicativos instalados manualmente

Você também pode usar `~/Applications/NOME-DO-APP`, se preferir um nome mais explícito.

## Fluxo padrão de instalação

Substitua os placeholders:

- `NOME-DO-APP` = nome do programa, por exemplo `antigravity`
- `ARQUIVO-BAIXADO.tar.gz` = nome real do arquivo baixado
- `CAMINHO-DO-EXECUTAVEL` = caminho completo do executável encontrado após extrair

### 1. Baixe o arquivo oficial

Baixe o arquivo no site oficial do aplicativo.

Normalmente ele vai para:

```text
~/Downloads
```

Confirme:

```bash
cd ~/Downloads
ls -lh ARQUIVO-BAIXADO.tar.gz
```

**O que faz:**

- `cd ~/Downloads` entra na pasta de downloads
- `ls -lh` lista o arquivo com tamanho legível

### 2. Crie a pasta de destino

```bash
mkdir -p ~/.local/opt/NOME-DO-APP
```

**O que faz:**

- `mkdir` cria pasta
- `-p` cria pastas pai necessárias e não dá erro se a pasta já existir
- `~/.local/opt/NOME-DO-APP` é onde o programa ficará

### 3. Extraia o arquivo

Para `.tar.gz`:

```bash
tar -xzf ARQUIVO-BAIXADO.tar.gz -C ~/.local/opt/NOME-DO-APP --strip-components=1
```

Para `.tar.xz`:

```bash
tar -xJf ARQUIVO-BAIXADO.tar.xz -C ~/.local/opt/NOME-DO-APP --strip-components=1
```

**O que faz:**

- `tar` manipula arquivos `.tar`
- `-x` extrai
- `-z` descomprime gzip, usado em `.tar.gz`
- `-J` descomprime xz, usado em `.tar.xz`
- `-f` indica o arquivo a ser aberto
- `-C` define a pasta de destino
- `--strip-components=1` remove o primeiro nível de pastas do arquivo compactado

Importante: use `--strip-components=1` apenas se o tarball tiver uma pasta raiz, por exemplo:

```text
Antigravity-x64/
├── antigravity
├── resources/
└── locales/
```

Assim, o conteúdo vai direto para:

```text
~/.local/opt/NOME-DO-APP/
```

Se você não souber se há pasta raiz, primeiro liste o conteúdo:

```bash
tar -tzf ARQUIVO-BAIXADO.tar.gz | head
```

**O que faz:**

- `-t` lista o conteúdo sem extrair
- `-z` indica compressão gzip
- `-f` indica o arquivo
- `| head` mostra apenas as primeiras linhas

Se as primeiras linhas começarem com `NOME-DO-APP/` ou `Pasta-Do-App/`, use `--strip-components=1`.

Se os arquivos já estiverem na raiz, por exemplo `./antigravity`, `./resources`, não use `--strip-components=1`.

### 4. Encontre o executável

```bash
find ~/.local/opt/NOME-DO-APP -maxdepth 3 -type f -perm -u+x
```

**O que faz:**

- `find` procura arquivos
- `-maxdepth 3` limita a busca a três níveis
- `-type f` busca apenas arquivos
- `-perm -u+x` mostra apenas arquivos executáveis pelo seu usuário

Procure pelo binário principal. Ele geralmente tem o nome do aplicativo, por exemplo:

```text
/home/dan/.local/opt/antigravity/antigravity
```

Arquivos como `chrome-sandbox`, `chrome_crashpad_handler`, `libffmpeg.so` e similares normalmente são dependências internas; não execute esses diretamente.

### 5. Teste o programa

```bash
CAMINHO-DO-EXECUTAVEL
```

Exemplo:

```bash
~/.local/opt/antigravity/antigravity
```

**O que faz:** executa o programa pelo caminho completo.

Se abrir normalmente, siga para criar o atalho no KDE.

## Criar atalho no KDE Plasma

### 1. Crie o arquivo `.desktop`

```bash
nano ~/.local/share/applications/NOME-DO-APP.desktop
```

**O que faz:** abre o editor `nano` para criar o atalho do menu.

Cole este modelo:

```ini
[Desktop Entry]
Type=Application
Name=NOME-DO-APP
Exec=CAMINHO-DO-EXECUTAVEL
Icon=CAMINHO-DO-ICONE
Terminal=false
Categories=Development;Utility;
```

Substitua:

- `NOME-DO-APP` pelo nome que aparecerá no menu
- `CAMINHO-DO-EXECUTAVEL` pelo caminho completo encontrado no passo anterior
- `CAMINHO-DO-ICONE` pelo caminho de um ícone, se existir

Se não houver ícone próprio, use um ícone genérico:

```ini
Icon=applications-development
```

Para aplicativo de desenvolvimento, use:

```ini
Categories=Development;IDE;
```

Para aplicativo comum, use:

```ini
Categories=Utility;
```

Salve com `Ctrl+O`, confirme com `Enter` e saia com `Ctrl+X`.

### 2. Atualize o menu

```bash
update-desktop-database ~/.local/share/applications
```

**O que faz:** registra o novo atalho para o KDE encontrá-lo.

Se não aparecer no menu, faça logout/login ou rode:

```bash
kbuildsycoca6
```

## Exemplo real: Google Antigravity

### Baixar e extrair

```bash
cd ~/Downloads
mkdir -p ~/.local/opt/antigravity
tar -xzf Antigravity.tar.gz -C ~/.local/opt/antigravity --strip-components=1
```

### Encontrar o executável

```bash
find ~/.local/opt/antigravity -maxdepth 3 -type f -perm -u+x
```

No caso do Antigravity x64, o executável foi:

```text
/home/dan/.local/opt/Antigravity-x64/antigravity
```

### Criar o atalho

```bash
nano ~/.local/share/applications/antigravity.desktop
```

Conteúdo:

```ini
[Desktop Entry]
Type=Application
Name=Google Antigravity
Exec=/home/dan/.local/opt/Antigravity-x64/antigravity
Icon=applications-development
Terminal=false
Categories=Development;IDE;
```

Atualize o menu:

```bash
update-desktop-database ~/.local/share/applications
```

## Atualizar um app instalado por tarball

### Método seguro: manter a versão antiga

```bash
mv ~/.local/opt/NOME-DO-APP ~/.local/opt/NOME-DO-APP-old
cd ~/Downloads
tar -xzf ARQUIVO-BAIXADO.tar.gz -C ~/.local/opt/NOME-DO-APP --strip-components=1
```

Teste o programa. Se estiver tudo certo, remova o backup:

```bash
rm -rf ~/.local/opt/NOME-DO-APP-old
```

**O que fazem:**

- `mv` renomeia a instalação antiga para `NOME-DO-APP-old`
- `tar -xzf ...` extrai a nova versão
- `rm -rf ...-old` apaga o backup depois de confirmar que a nova versão funciona

Atenção: `rm -rf` apaga definitivamente, sem lixeira.

## Remover um app instalado por tarball

```bash
rm -rf ~/.local/opt/NOME-DO-APP
rm -f ~/.local/share/applications/NOME-DO-APP.desktop
```

**O que faz:**

- primeiro comando apaga a pasta do programa
- segundo comando apaga o atalho do menu

## Boas práticas no Aurora

- Prefira **Flatpak/Bazaar** para apps gráficos disponíveis no Flathub.
- Prefira **Homebrew** para ferramentas de terminal.
- Use tarball manual apenas quando o app não tiver Flatpak, Brew ou pacote oficial adequado.
- Mantenha cada app em sua própria pasta: `~/.local/opt/nome-do-app`.
- Não misture vários apps dentro da mesma pasta.
- Guarde o link da página oficial de download junto com suas anotações.
- Antes de atualizar, renomeie a versão antiga para `...-old`; isso cria um rollback simples.
- Não use `sudo` nem instale em `/opt` do sistema, a menos que tenha um motivo específico; no Aurora, isso pode complicar atualizações e rollback.

## Checklist rápido

```bash
# 1. Ver arquitetura
uname -m

# 2. Ir aos downloads e conferir o arquivo
cd ~/Downloads
ls -lh ARQUIVO-BAIXADO.tar.gz

# 3. Criar pasta
mkdir -p ~/.local/opt/NOME-DO-APP

# 4. Ver conteúdo do tarball antes de extrair
tar -tzf ARQUIVO-BAIXADO.tar.gz | head

# 5. Extrair
tar -xzf ARQUIVO-BAIXADO.tar.gz -C ~/.local/opt/NOME-DO-APP --strip-components=1

# 6. Encontrar executável
find ~/.local/opt/NOME-DO-APP -maxdepth 3 -type f -perm -u+x

# 7. Criar atalho
nano ~/.local/share/applications/NOME-DO-APP.desktop

# 8. Atualizar menu
update-desktop-database ~/.local/share/applications
```
