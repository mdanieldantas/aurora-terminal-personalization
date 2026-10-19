# Aurora em Coleções — Referência do bbrew

Documento 2 de 3 · Projeto Aurora Pronto  
Versão 1.0 · 7 de outubro de 2026  
Projeto de Marcos Daniel Gomes Dantas

Manual de consulta para conhecer o Bold Brew, examinar Brewfiles e instalar ferramentas seletivamente no Aurora Linux. Não é uma lista de comandos para executar de uma vez.

> Regra do projeto: ler a coleção, comparar com o que já existe e decidir o que realmente será usado. Não instalar todas as coleções para “completar” o Aurora.

<a id="indice"></a>
## Índice

- [1. Entender os componentes](#componentes)
- [2. Consultar sem instalar](#consultar)
- [3. Catálogo das coleções](#catalogo)
- [ai-tools — inteligência artificial](#ai-tools)
- [artwork — recursos visuais](#artwork)
- [cli — terminal](#cli)
- [cncf — cloud-native](#cncf)
- [experimental-ide — desenvolvimento experimental](#experimental-ide)
- [fonts — fontes](#fonts)
- [full-desktop — aplicativos KDE](#full-desktop)
- [ide — editores e desenvolvimento](#ide)
- [k8s-tools — Kubernetes](#k8s-tools)
- [swift — linguagem Swift](#swift)
- [Flatpaks padrão e DX](#flatpaks-padrao)
- [4. Instalar e evitar duplicidade](#instalar)
- [5. Registro e solução de problemas](#registro)

<a id="componentes"></a>
## 1. Entender os componentes

### O que é Bold Brew

Bold Brew, executável `bbrew`, é uma interface de terminal interativa (TUI) para pesquisar e administrar pacotes. Seu projeto documenta suporte a fórmulas Homebrew, casks, Flatpaks e entradas de Brewfile. Não é outra distribuição nem substitui os gerenciadores que executam a instalação. [web:248]

É importante corrigir uma simplificação das respostas anteriores: `bbrew` não é apenas o menu de nomes `ai-tools`, `fonts` e `ide`. O programa tem uma interface própria de gerenciamento de pacotes, enquanto o Aurora oferece uma receita `ujust bbrew` para trabalhar com suas coleções. [web:17][web:248]

### Cinco nomes diferentes

| Nome | Função | Exemplo |
|---|---|---|
| Homebrew | Gerenciador de pacotes | `brew list` |
| Bold Brew | Interface interativa de gerenciamento | `bbrew` |
| Brewfile | Arquivo que declara dependências | `ai-tools.Brewfile` |
| Homebrew Bundle | Aplica ou verifica um Brewfile | `brew bundle check --file=...` |
| ujust | Executa receitas do Aurora | `ujust bbrew` |

O Bundle declara o estado que se deseja atingir: instalar itens ausentes e, por padrão, atualizar os desatualizados. Um Brewfile não equivale a um arquivo que trava todas as versões. [web:72]

### Os comandos não são equivalentes

| Comando | Comportamento | Cuidado |
|---|---|---|
| `cat arquivo.Brewfile` | Mostra o texto | Não instala |
| `brew bundle check --file=...` | Verifica dependências | Usar arquivo confiável |
| `bbrew` | Abre a interface geral | Ações de instalar, remover e atualizar mudam o sistema |
| `bbrew -f arquivo.Brewfile` | Abre a interface com uma coleção | Conferir suporte em `bbrew --help` |
| `ujust bbrew` | Executa a receita Aurora | O comportamento depende da receita local |
| `brew bundle install --file=...` | Processa todas as entradas aplicáveis | Não é uma tela de pré-visualização |

O modo `bbrew -f` está documentado pelo próprio Bold Brew. Ele permite navegar pelos pacotes de uma coleção, em vez de aplicar cegamente todo o arquivo com Bundle. [web:248]

Antes de assumir que selecionar uma coleção sempre instala tudo, confira a receita local:

```bash
type -a bbrew
bbrew --help
ujust -n bbrew
```

O `type -a` também identifica aliases ou funções que possam mudar o significado de `bbrew`. O `ujust -n` mostra os comandos sem executar a receita; não simula todos os efeitos dos programas chamados. [web:17]

### O que significam as linhas

| Prefixo | Significado | Exemplo do seu Aurora |
|---|---|---|
| `tap` | Fonte adicional de definições Homebrew | `tap "ublue-os/tap"` |
| `brew` | Fórmula Homebrew | `brew "llm"` |
| `cask` | Aplicativo/binário empacotado como cask | `cask "ublue-os/tap/lm-studio-linux"` |
| `flatpak` | Pacote a ser administrado pelo Flatpak | `flatpak "ai.jan.Jan"` |
| `#` | Comentário | Descrição do arquivo |

Um cask não é necessariamente um aplicativo gráfico: Claude Code, Codex e Copilot CLI aparecem como casks no seu arquivo de IA, embora sejam ferramentas de terminal. O formato de distribuição não define a interface do programa. O Bundle suporta esses diferentes tipos. [web:72]

Os casks Linux do Universal Blue pertencem aos taps que os distribuem. Não presumir que todo cask do catálogo macOS funciona no Linux.

[Voltar ao índice](#indice)

<a id="consultar"></a>
## 2. Consultar sem instalar

### Encontrar as coleções locais

No Aurora mostrado nesta sessão:

```bash
ls -1 /usr/share/ublue-os/homebrew/
```

Foram vistos 12 arquivos: 10 coleções do menu e dois conjuntos de Flatpaks padrão. A pasta da máquina é a referência para seu sistema; o conteúdo online pode estar à frente ou atrás da imagem instalada.

### Ler a lista real

```bash
cat /usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

Se `cat` estiver configurado como alias para `bat`, a saída aparece com cores e números de linha. Isso não executa o Brewfile. Para usar a leitura convencional:

```bash
command cat /usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

Para ver as linhas comuns de declaração:

```bash
grep -E '^[[:space:]]*(tap|brew|cask|flatpak)[[:space:]]' \
  /usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

Esse filtro não é um analisador completo: Brewfiles podem conter condições Ruby, chamadas de sistema e declarações em várias linhas. Leia o arquivo inteiro antes de executá-lo. Até `bundle check` avalia a lógica Ruby do Brewfile; por isso, não usá-lo em arquivos desconhecidos como se fosse uma sandbox. [web:72]

### Conferir dependências

```bash
brew bundle check \
  --file=/usr/share/ublue-os/homebrew/ai-tools.Brewfile \
  --verbose
```

- Dependências satisfeitas: não há nada pendente segundo a verificação do Bundle.
- Dependências não satisfeitas: revisar a lista; o código de saída pode ser diferente de zero.
- Isso não prova que aplicativos equivalentes instalados por outros métodos sejam reconhecidos.

A documentação mostra `check` para verificar se uma aplicação do Bundle terá trabalho a fazer e `--verbose` para detalhar dependências não satisfeitas. Não chamar isso de simulação completa da instalação. [web:72]

### Listar declarações pelo Bundle

Por tipo:

```bash
brew bundle list --formula \
  --file=/usr/share/ublue-os/homebrew/ai-tools.Brewfile

brew bundle list --cask \
  --file=/usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

Conferir outras opções disponíveis na sua versão:

```bash
brew bundle --help
```

A lista do Brewfile descreve o conjunto desejado, não o conjunto já instalado. Condições do arquivo podem alterar o resultado conforme a máquina. [web:72]

### Conferir instalações existentes

```bash
brew list --formula
brew list --cask
brew list --versions
brew tap
flatpak list --app --system
flatpak list --app --user
```

Para um pacote específico:

```bash
brew info llm
brew info --cask ublue-os/tap/lm-studio-linux
```

Essas consultas podem acessar metadados/rede; não são comandos de instalação da coleção.

### Abrir uma coleção no Bold Brew

Primeiro confirme que sua versão reconhece `-f`:

```bash
bbrew --help
```

Depois:

```bash
bbrew -f /usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

O projeto documenta esse modo para apresentar uma coleção no TUI. Não usar comandos de instalar/atualizar/remover apenas para navegar. [web:248]

Atalhos documentados podem variar entre versões:

| Tecla | Ação |
|---|---|
| `/` | Pesquisa |
| `f` | Filtro |
| `i` | Instalação de pacote |
| `u` | Atualização de pacote |
| `r` | Remoção de pacote |
| `q` | Sair |
| `Ctrl+U` | Atualização em massa |

Confira a ajuda/rodapé da interface antes de agir. Esses atalhos pertencem ao Bold Brew, não necessariamente ao seletor de receitas do `ujust`. Algumas versões têm recursos adicionais, como exportação e análise de vulnerabilidades; não ativá-los supondo que todas as ações sejam apenas leitura. [web:246][web:248]

[Voltar ao índice](#indice)

<a id="catalogo"></a>
## 3. Catálogo das coleções

### Como interpretar este catálogo

| Evidência | Significado |
|---|---|
| Arquivo fornecido | Conteúdo do Brewfile colado pelo usuário |
| Saída de instalação | Itens vistos em `Using`/`Installing`; não necessariamente todas as declarações do arquivo |
| Inventário instalado | Pacotes encontrados no `brew list`; pode incluir dependências |
| Lista local pendente | Finalidade geral documentada; não temos a lista exata dessa versão |

Não confundir uma lista exemplificativa da documentação com a composição exata de um Brewfile. Para coleções não fornecidas, este documento mostra como ler o arquivo, sem inventar os aplicativos.

<a id="ai-tools"></a>
### ai-tools — inteligência artificial

Arquivo local:

```bash
cat /usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

Evidência: arquivo fornecido pelo usuário. São 19 declarações: 4 taps, 7 fórmulas, 7 casks e 1 Flatpak — portanto, 15 entradas de software, além das fontes de pacotes. Dependências adicionais e downloads posteriores de modelos não estão incluídos nessa contagem.

Taps declarados:

```text
anomalyco/tap
llmmanorg/tap
ublue-os/tap
ublue-os/experimental-tap
```

| Entrada | Interface/tipo no arquivo | Finalidade |
|---|---|---|
| `anomalyco/tap/opencode` | Fórmula; agente de terminal | Assistência à programação com modelos de IA. [web:273] |
| `block-goose-cli` | Fórmula; CLI | Agente Goose para automatizar tarefas e integrar ferramentas, inclusive MCP. [web:259][web:264] |
| `llm` | Fórmula; CLI/biblioteca | Executar prompts e acessar modelos por APIs ou plugins. [web:275] |
| `llmfit` | Fórmula; terminal | Estimar quais modelos cabem e podem funcionar no hardware disponível. Estimativas não são garantia de desempenho. [web:278] |
| `llmmanorg/tap/llmman` | Fórmula; CLI | Trabalhar com modelos como artefatos OCI e conectá-los a clientes/agentes. [web:293][web:294] |
| `ramalama` | Fórmula; CLI | Gerenciar e executar modelos, normalmente em containers Podman/Docker. [web:289][web:291] |
| `ublue-os/tap/linux-mcp-server` | Fórmula; servidor MCP | Expor informações Linux, como processos, logs e estado de serviços, a clientes compatíveis com MCP. [web:284] |
| `claude-code` | Cask; ferramenta de terminal | Agente de programação da Anthropic. [web:267] |
| `codex` | Cask; ferramenta de terminal | Agente de programação da OpenAI. [web:267] |
| `copilot-cli` | Cask; ferramenta de terminal | Agente GitHub Copilot no terminal. [web:267] |
| `ublue-os/tap/antigravity-linux` | Cask; aplicativo | Ambiente/plataforma de desenvolvimento com agentes do Google. O tap empacota o aplicativo; não é o criador do produto. [web:260] |
| `ublue-os/experimental-tap/opencode-desktop-linux` | Cask; aplicativo | Interface desktop do OpenCode, distribuída pelo tap experimental. [web:273] |
| `ublue-os/tap/goose-linux` | Cask; aplicativo | Interface desktop Goose, distinta da entrada CLI. [web:259][web:264] |
| `ublue-os/tap/lm-studio-linux` | Cask; aplicativo | Outra distribuição do LM Studio; comparar com seu Flatpak já instalado |
| `ai.jan.Jan` | Flatpak; aplicativo | Entrada Jan da coleção; conferir a descrição da versão no Flathub antes de instalar |

Fórmula e cask de uma mesma família podem coexistir intencionalmente: Goose CLI e Goose desktop têm interfaces diferentes. Não classificá-los automaticamente como uma duplicata indevida.

Cuidados:

- LM Studio já existe na máquina como `ai.lmstudio.lm-studio`; o cask pode criar outra edição.
- Contas, APIs, assinaturas e modelos não ficam automaticamente configurados com a instalação do cliente.
- Instalar o cliente não significa baixar todos os modelos, mas seu uso pode baixar arquivos grandes.
- Agentes podem ler projetos, alterar arquivos e executar comandos conforme suas permissões. Revisar configurações antes de apontá-los para pastas com segredos.
- Servidores MCP podem expor dados sensíveis. Instalar não significa autorizar acesso irrestrito à máquina.
- `llmfit` recomenda/estima; `ramalama` executa modelos. São finalidades diferentes. [web:278][web:291]

Decisão do projeto: não instalar a coleção completa. Selecionar uma ferramenta quando houver uma tarefa concreta.

[Voltar ao índice](#indice)

<a id="artwork"></a>
### artwork — recursos visuais

```bash
cat /usr/share/ublue-os/homebrew/artwork.Brewfile
```

Evidência: arquivo local ainda não fornecido.

A descrição anterior como “somente wallpapers do Aurora/Bluefin/Bazzite” não foi confirmada para o seu arquivo. A categoria pode agrupar recursos visuais ou ferramentas relacionadas a arte/design, conforme a versão. Não assumir uma composição pelo nome.

O que verificar: se contém arquivos de arte, fontes, aplicativos de design ou outros casks. Depois, decidir se isso atende a uma necessidade real.

Decisão: opcional, sem instalação automática e sem lista de aplicativos inventada.

[Voltar ao índice](#indice)

<a id="cli"></a>
### cli — terminal

```bash
cat /usr/share/ublue-os/homebrew/cli.Brewfile
```

Evidência: inventário Homebrew e documentação Aurora CLI; o arquivo local completo ainda não foi fornecido.

A seleção moderna de CLI do Aurora inclui ferramentas de histórico, busca, prompt, arquivos, dotfiles e desenvolvimento. A lista pública pode mudar e não coincide necessariamente com cada versão local. [web:31]

Principais itens presentes no seu `brew list`:

| Pacote | Comando comum | Utilidade |
|---|---|---|
| `atuin` | `atuin` | Histórico pesquisável; sincronização quando configurada |
| `bat` | `bat` | Exibir arquivos com destaque de sintaxe |
| `chezmoi` | `chezmoi` | Administrar dotfiles |
| `direnv` | `direnv` | Ambientes por diretório |
| `dysk` | `dysk` | Informações dos discos montados |
| `eza` | `eza` | Listagem de arquivos |
| `fd` | `fd` | Encontrar arquivos |
| `gh` | `gh` | GitHub no terminal |
| `ripgrep` | `rg` | Busca de texto |
| `starship` | `starship` | Prompt do shell |
| `tealdeer` | `tldr` | Exemplos rápidos de comandos |
| `trash-cli` | `trash-put` | Enviar arquivos à lixeira |
| `ugrep` | `ugrep` | Busca avançada de texto |
| `uutils-coreutils` | Conferir comandos instalados | Implementações de utilitários de sistema |
| `yq` | `yq` | Processar dados estruturados |
| `zoxide` | `zoxide` | Navegação baseada em histórico |

As funções dessa seleção estão descritas na documentação Aurora CLI. Pacotes instalados não implicam hooks, autenticação ou sincronização já configurados. [web:31]

Também aparecem `mise`, `yazi`, `podman-tui`, Bash, Python e bibliotecas. Não atribuir todos automaticamente ao `cli.Brewfile`: alguns podem ser dependências ou instalações anteriores.

Verificação:

```bash
brew bundle check --file=/usr/share/ublue-os/homebrew/cli.Brewfile --verbose
```

Decisão: Aurora CLI já foi executado; conferir antes de instalar qualquer complemento. Não introduzir hooks repetidos de Starship, Atuin, direnv ou zoxide em arquivos de shell sem revisar a configuração existente.

[Voltar ao índice](#indice)

<a id="cncf"></a>
### cncf — cloud-native

```bash
cat /usr/share/ublue-os/homebrew/cncf.Brewfile
```

Evidência: finalidade documentada; lista exata local pendente.

A coleção se destina a ferramentas do ecossistema cloud-native/CNCF. A receita `ujust cncf` é descrita pelo Aurora como abertura do Bold Brew com o Brewfile CNCF. Não afirmar que ela sempre instala tudo imediatamente. [web:17]

Pode haver sobreposição com Kubernetes e outras coleções; compare os IDs reais antes de selecionar. Não registrar uma contagem de ferramentas nem nomes específicos sem ler seu arquivo.

Decisão: fora da instalação padrão. Só considerar ao definir um fluxo concreto de infraestrutura/DevOps.

[Voltar ao índice](#indice)

<a id="experimental-ide"></a>
### experimental-ide — desenvolvimento experimental

```bash
cat /usr/share/ublue-os/homebrew/experimental-ide.Brewfile
```

Evidência: arquivo local pendente.

É uma coleção separada para ferramentas de desenvolvimento apresentadas como experimentais. Isso não permite concluir que cada aplicativo seja instável: a classificação pode refletir o estado do empacotamento ou da integração.

Verificar pacote por pacote, fonte, permissões e relação com coleções `ide` e `ai-tools`. Não presumir que os mesmos aplicativos aparecem em todos esses arquivos.

Decisão: não instalar por padrão. Usar em testes controlados, quando houver interesse específico.

[Voltar ao índice](#indice)

<a id="fonts"></a>
### fonts — fontes

```bash
cat /usr/share/ublue-os/homebrew/fonts.Brewfile
```

Evidência: log de instalação e inventário Homebrew. Os 11 casks confirmados são:

| Cask | Nome/família |
|---|---|
| `font-0xproto-nerd-font` | 0xProto Nerd Font |
| `font-blex-mono-nerd-font` | Blex Mono Nerd Font |
| `font-caskaydia-mono-nerd-font` | Caskaydia Mono Nerd Font |
| `font-comic-shanns-mono-nerd-font` | Comic Shanns Mono Nerd Font |
| `font-droid-sans-mono-nerd-font` | Droid Sans Mono Nerd Font |
| `font-fira-code-nerd-font` | Fira Code Nerd Font |
| `font-go-mono-nerd-font` | Go Mono Nerd Font |
| `font-jetbrains-mono-nerd-font` | JetBrains Mono Nerd Font |
| `font-sauce-code-pro-nerd-font` | Sauce Code Pro Nerd Font |
| `font-source-code-pro` | Source Code Pro, entrada sem o sufixo Nerd Font |
| `font-ubuntu-nerd-font` | Ubuntu Nerd Font |

São opções de fonte, não 11 aplicativos. Uma família pode instalar vários arquivos de estilo. Instalar não escolhe automaticamente a fonte do perfil Konsole ou VS Code.

Verificação:

```bash
brew list --cask | grep -i '^font-'
```

Decisão: já atendida por `ujust aurora-fonts`. Não executar novamente pelo Embellish para obter os mesmos arquivos sem motivo.

[Voltar ao índice](#indice)

<a id="full-desktop"></a>
### full-desktop — aplicativos KDE

```bash
cat /usr/share/ublue-os/homebrew/full-desktop.Brewfile
```

Evidência: arquivo fornecido. São 11 entradas Flatpak, não um requisito de funcionamento do KDE.

| ID | Aplicativo | Finalidade |
|---|---|---|
| `org.kde.elisa` | Elisa | Reproduzir e organizar músicas |
| `org.kde.kasts` | Kasts | Podcasts |
| `org.kde.kamoso` | Kamoso | Fotos e vídeos da webcam |
| `org.kde.CrowTranslate` | Crow Translate | Tradução de textos |
| `org.kde.marknote` | Marknote | Notas e cadernos |
| `org.kde.alligator` | Alligator | Leitura de feeds RSS |
| `org.kde.tokodon` | Tokodon | Cliente Mastodon/Fediverso |
| `org.kde.neochat` | NeoChat | Conversas na rede Matrix |
| `org.kde.keysmith` | Keysmith | Códigos de autenticação de dois fatores |
| `org.kde.merkuro` | Merkuro | Calendário e contatos |
| `org.kde.kid3` | Kid3 | Editar metadados de arquivos de áudio |

Essas finalidades constam no catálogo de aplicativos KDE. Marknote também documenta notas em Markdown e organização em cadernos. [web:118][web:119][web:120]

Decisão do usuário: não instalar essa coleção. Se houver necessidade futura, escolher um aplicativo individual pelo Bazaar/Flatpak.

[Voltar ao índice](#indice)

<a id="ide"></a>
### ide — editores e desenvolvimento

```bash
cat /usr/share/ublue-os/homebrew/ide.Brewfile
```

Evidência: arquivo fornecido. Contém 1 tap, 6 casks e 4 fórmulas: 10 entradas de software.

| Entrada | Tipo | Função |
|---|---|---|
| `ublue-os/tap/visual-studio-code-linux` | Cask | VS Code estável. [web:302] |
| `ublue-os/tap/visual-studio-code-linux@insiders` | Cask | VS Code de prévia; instalado separadamente da edição estável. [web:133] |
| `ublue-os/tap/vscodium-linux` | Cask | Distribuição comunitária dos binários baseados no código do VS Code, com configuração sem telemetria Microsoft. Não é apenas uma extensão. [web:307][web:313] |
| `ublue-os/tap/antigravity-linux` | Cask | Ambiente de agentes de desenvolvimento do Google. [web:260] |
| `ublue-os/tap/jetbrains-toolbox-linux` | Cask | Gerenciador para instalar/atualizar IDEs JetBrains; não significa instalar todas as IDEs. [web:30] |
| `ublue-os/tap/zed-linux` | Cask | Editor com colaboração e recursos de IA. [web:139] |
| `nvim` | Fórmula | Neovim; editor modal, normalmente aberto como `nvim` |
| `micro` | Fórmula | Editor de texto no terminal, normalmente aberto como `micro` |
| `helix` | Fórmula | Editor modal de terminal, normalmente aberto como `hx`; integração com LSP e Tree-sitter. [web:309][web:314] |
| `devcontainer` | Fórmula | CLI que cria/configura ambientes a partir de `devcontainer.json`. Não é DevPod nem um motor de containers. [web:306][web:310] |

Verificações úteis:

```bash
brew list --cask
brew list --formula
type -a code
command -v nvim
command -v micro
command -v hx
command -v devcontainer
```

Se `command -v` não retorna caminho, o comando não foi encontrado no PATH; isso não prova ausência de uma edição isolada em container ou outro local.

Cuidados desta máquina:

- VS Code já aparece como Flatpak `com.visualstudio.code`.
- A imagem DX também pode incluir VS Code; conferir a base antes de concluir que há somente uma edição. [web:30]
- Nenhum dos casks IDE aparece no inventário Homebrew enviado.
- Antigravity também está no `ai-tools.Brewfile`; não é necessário instalá-lo duas vezes para usar as duas coleções.
- Dev Container CLI não foi encontrado no PATH; decisão do usuário: não instalar agora.
- VS Code Insiders e estável podem coexistir propositalmente, mas não são necessários para todo projeto. [web:133]

Decisão: não instalar a coleção inteira. Manter o editor atual e avaliar uma ferramenta por necessidade.

[Voltar ao índice](#indice)

<a id="k8s-tools"></a>
### k8s-tools — Kubernetes

```bash
cat /usr/share/ublue-os/homebrew/k8s-tools.Brewfile
```

Evidência: finalidade identificada; lista exata local pendente.

Coleção para fluxos de Kubernetes. Instalar os clientes/utilitários não equivale automaticamente a criar um cluster, configurá-lo ou iniciar todos os serviços.

As respostas anteriores citaram listas exemplificativas como `kubectl`, `helm`, `k9s`, `kind`, `grype` e `syft`. Esses nomes não devem ser registrados como composição confirmada desta versão sem ler o arquivo.

Decisão: fora da instalação inicial. Para trabalhar somente com Podman, não é necessário instalar essa coleção.

[Voltar ao índice](#indice)

<a id="swift"></a>
### swift — linguagem Swift

```bash
cat /usr/share/ublue-os/homebrew/swift.Brewfile
```

Evidência: arquivo local pendente. A categoria destina-se ao desenvolvimento Swift; confirmar as entradas e versões na lista local.

Não confundir ferramentas Swift para Linux com um ambiente completo de desenvolvimento de aplicativos Apple/Xcode.

Decisão: não instalar, salvo se surgir um projeto que use Swift.

[Voltar ao índice](#indice)

<a id="flatpaks-padrao"></a>
### Flatpaks padrão e DX

Estes dois arquivos estavam presentes na pasta, mas não apareceram entre as 10 opções do menu mostrado. São conjuntos auxiliares da configuração Aurora, não necessariamente categorias selecionáveis no bbrew.

```bash
cat /usr/share/ublue-os/homebrew/system-flatpaks.Brewfile
cat /usr/share/ublue-os/homebrew/system-dx-flatpaks.Brewfile
```

O instalador oficial de Flatpaks padrão é:

```bash
ujust install-system-flatpaks
```

A receita é documentada como útil após rebase. Conferir os parâmetros/receita local antes de presumir que uma chamada sem argumentos sempre processa ambos os arquivos. [web:17]

system-flatpaks: a execução enviada mostrou 22 dependências satisfeitas. Entre os aplicativos estavam Flatseal, Kontainer, Warehouse, Bazaar, Mission Center, Deskflow, Fedora Media Writer, KTailctl, Déjà Dup, Firmware, Gwenview, Haruna, KCalc, KClock, Kontact, KWeather, Okular, Qrca, Skanpage, Thunderbird e Firefox. O tema GTK Breeze apareceu como `Installing`. Isso representa a saída daquela execução, não uma garantia de composição para toda versão.

system-dx-flatpaks: arquivo fornecido com três entradas:

| ID | Aplicativo | Finalidade |
|---|---|---|
| `io.podman_desktop.PodmanDesktop` | Podman Desktop | Interface gráfica para containers e integração com Kubernetes. [web:187] |
| `io.github.getnf.embellish` | Embellish | Administrar Nerd Fonts pela interface gráfica. [web:184] |
| `me.iepure.devtoolbox` | Dev Toolbox | Conversões e utilitários gráficos de desenvolvimento. Não é o comando Toolbx. [web:185] |

Os três foram confirmados pelo usuário. Não precisam ser instalados novamente por causa deste documento.

[Voltar ao índice](#indice)

<a id="instalar"></a>
## 4. Instalar e evitar duplicidade

### Fluxo recomendado

1. Ler o Brewfile local.
2. Conferir Homebrew, Flatpak system e Flatpak user.
3. Verificar possíveis AppImages e pacotes da imagem quando relevante.
4. Escolher somente os programas necessários.
5. Executar a instalação escolhida, sem automações desnecessárias.
6. Conferir a origem e o funcionamento depois.

### Instalar um item individual

Exemplos — não executar todos:

```bash
brew install llm
```

```bash
brew install ramalama
```

Para um cask específico, após revisar suas informações:

```bash
brew info --cask ublue-os/tap/zed-linux
brew install --cask ublue-os/tap/zed-linux
```

A entrada qualificada informa o tap. Se houver uma solicitação de confiança, erro de plataforma ou conflito, leia a mensagem; não habilite confiança global nem use `--force` como resposta automática.

### Aplicar uma coleção inteira

Somente depois de aprovar todas as entradas:

```bash
brew bundle install \
  --file=/usr/share/ublue-os/homebrew/ai-tools.Brewfile \
  --no-upgrade
```

`--no-upgrade` evita a tentativa normal de upgrade feita pelo Bundle, mas ainda permite instalação de itens ausentes. Não trava versões, não impede downloads e não elimina possíveis efeitos de scripts de instalação. Não substitui uma auditoria de duplicidades. [web:72]

Se não houver interesse na coleção toda, não usar esse comando.

### Criar uma seleção pessoal

Não editar arquivos de `/usr/share` para ajustar uma instalação pessoal. Eles pertencem à imagem e podem mudar nas atualizações.

Exemplo de um Brewfile pessoal mínimo:

```bash
mkdir -p "$HOME/aurora-pos-instalacao/config"
cat > "$HOME/aurora-pos-instalacao/config/ai-selecionadas.Brewfile" <<'EOF'
brew "llm"
brew "ramalama"
EOF
```

Esse comando só grava o arquivo, não instala. O exemplo sobrescreve um arquivo existente com esse mesmo nome: use outro nome ou faça backup se já tiver uma seleção.

Verificar:

```bash
brew bundle check \
  --file="$HOME/aurora-pos-instalacao/config/ai-selecionadas.Brewfile" \
  --verbose
```

Somente quando desejar instalar os dois itens:

```bash
brew bundle install \
  --file="$HOME/aurora-pos-instalacao/config/ai-selecionadas.Brewfile" \
  --no-upgrade
```

Esse é um exemplo de seleção, não uma recomendação de instalar ambos agora.

### O que é detectado como instalado

| Situação | O que pode acontecer |
|---|---|
| Mesma fórmula já instalada e adequada | Bundle pode mostrar `Using` |
| Mesma fórmula desatualizada | Bundle pode tentar upgrade |
| Pacote ausente | Bundle pode mostrar `Installing` |
| Aplicativo Flatpak também oferecido como cask | Pode instalar outra edição |
| Mesmo Flatpak em user e system | Podem existir duas instalações de escopo |
| Aplicativo em AppImage e Flatpak | Ambos podem continuar instalados |
| Mesmo comando no host e Distrobox | Ambientes diferentes; não necessariamente erro |
| Aplicativo fornecido pela imagem DX e via Flatpak | Pode haver duas origens; investigar sem remover a base |

O comportamento documentado de `Using`/instalação/upgrade vale para dependências reconhecidas pelo Bundle. Não garante identificação cruzada por nome comercial. [web:72]

Exemplo LM Studio:

```bash
flatpak info --system ai.lmstudio.lm-studio
flatpak info --user ai.lmstudio.lm-studio
brew list --cask | grep -i 'lm-studio'
```

Exemplo VS Code:

```bash
flatpak info --system com.visualstudio.code
flatpak info --user com.visualstudio.code
brew list --cask | grep -Ei 'visual-studio-code|vscodium'
type -a code
rpm -qa | grep -Ei '(^code-|vscodium)'
```

`type -a` não lista automaticamente todas as edições Flatpak e pode mostrar aliases/wrappers, não cópias físicas. Não remover nada apenas por aparecerem dois caminhos.

### Não usar cleanup para “desfazer”

Não executar `brew bundle cleanup --force` com um Brewfile pequeno para tentar reverter uma coleção: isso pode remover outros pacotes não listados no arquivo e, em versões atuais, alterar o conjunto de confiança dos taps. [web:72]

Um Bundle não é uma transação reversível única. Remover apenas os pacotes que você identificou, preservando dependências e dados quando necessário. Desinstalar um cliente de IA não garante remover todos os modelos, caches, credenciais ou configurações criados depois.

[Voltar ao índice](#indice)

<a id="registro"></a>
## 5. Registro e solução de problemas

### Estado decidido neste projeto

| Item | Decisão |
|---|---|
| Aurora CLI | Já executado |
| Fontes Aurora | Já instaladas |
| Flatpaks padrão e três extras DX | Confirmados na sessão |
| full-desktop | Não instalar |
| ide completo | Não instalar em massa |
| Dev Container CLI | Não instalar agora |
| DevPod | Não instalar agora; não consta nos Brewfiles fornecidos |
| ai-tools | Examinar; selecionar itens por demanda |
| cncf/k8s-tools | Adiar até um objetivo concreto |
| artwork/experimental-ide/swift | Opcionais, sem instalação automática |

O inventário Homebrew enviado mostra fórmulas de terminal e bibliotecas, mais 11 casks de fontes. Não mostra casks de IDE/IA. Isso não prova ausência desses programas em RPM, Flatpak, AppImage ou containers.

### Quando faltar o arquivo

```bash
ls -1 /usr/share/ublue-os/homebrew/
ujust -n bbrew
```

Não baixar e aplicar automaticamente um Brewfile de outra distribuição para substituir um arquivo ausente. Registrar a edição/canal e verificar se o caminho mudou.

### “nothing selected” e código 1

A captura da sessão mostra `nothing selected` seguido de falha da receita `bbrew` com código 1. Nesse contexto, você cancelou/não escolheu uma coleção. Não indica que foi necessário reparar o Homebrew nem que uma nova coleção foi instalada.

Não generalizar: se aparecer outro erro ou se uma instalação já tiver começado, analisar aquela saída específica. Cancelar depois do início pode deixar parte da seleção instalada.

### Bundle repetido

O total `22 Brewfile dependencies now installed` é o conjunto satisfeito, não necessariamente 22 itens novos. Se quiser saber o que mudou, compare inventários anteriores e posteriores, além de ler `Using`, `Installing` e mensagens de falha. [web:72]

### Conferência de saúde

```bash
brew doctor
```

É um diagnóstico; não executar correções por reflexo. Em Aurora, caminhos e bibliotecas também podem fazer parte da imagem. Revisar o aviso antes de alterar a base.

### Salvar inventário e listas locais

A partir do terminal, este bloco grava arquivos de texto localmente; não instala coleções:

```bash
mkdir -p "$HOME/aurora-pos-instalacao/logs"
stamp="$(date +%Y%m%d-%H%M%S)"
{
  date
  brew --version
  command -v bbrew
  brew list --formula
  brew list --cask
  brew tap
  flatpak list --app --system
  flatpak list --app --user
} > "$HOME/aurora-pos-instalacao/logs/inventario-bbrew-$stamp.txt" 2>&1

for file in /usr/share/ublue-os/homebrew/*.Brewfile; do
  [ -f "$file" ] || continue
  printf '\n===== %s =====\n' "$file"
  command cat "$file"
done > "$HOME/aurora-pos-instalacao/logs/colecoes-bbrew-$stamp.txt"
```

O segundo arquivo permitirá completar as listas exatas ainda pendentes (`artwork`, `cli`, `cncf`, `experimental-ide`, `k8s-tools`, `swift` e definições completas dos arquivos padrão). Revisar informações pessoais antes de compartilhar inventários.

### Checklist antes de instalar

- [ ] Identifiquei se estou no Bold Brew, no seletor ujust ou no Bundle.
- [ ] Li o Brewfile completo e confio na fonte.
- [ ] Conferi o que já existe em Homebrew e Flatpak.
- [ ] Verifiquei os possíveis conflitos relevantes, inclusive LM Studio e VS Code.
- [ ] Escolhi somente programas necessários.
- [ ] Sei se haverá instalação, atualização ou remoção.
- [ ] Não estou usando `--force` para contornar um erro sem diagnóstico.
- [ ] Sei que a seleção inteira pode adicionar dependências além dos nomes listados.
- [ ] Vou testar o programa antes de configurar contas, modelos e permissões.

Este documento complementa o guia rápido Aurora Pronto. O próximo documento será a referência do ujust; por isso, não duplicamos aqui a explicação de todas as receitas do sistema.

Consulta oficial: [Bold Brew](https://bold-brew.com/), [Uso básico do Aurora](https://docs.getaurora.dev/guides/basic-usage/#curated-tool-bundles), [Aurora CLI](https://docs.getaurora.dev/guides/aurora-cli/#included-tools) e [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile).

[Voltar ao índice](#indice)
