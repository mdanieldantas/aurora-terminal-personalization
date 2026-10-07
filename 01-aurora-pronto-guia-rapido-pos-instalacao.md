# Aurora Pronto — Guia rápido de pós-instalação

Documento 1 de 3 · Projeto pessoal Aurora Linux / Aurora DX  
Versão 1.0 · 7 de outubro de 2026 · Autor do projeto: Marcos Daniel Gomes Dantas

Roteiro manual para preparar o Aurora, instalar somente o necessário e aplicar nossas personalizações. Não é um instalador automático: execute uma etapa por vez, leia a saída e pare se houver erro.

> Os documentos detalhados do bbrew e do ujust serão complementares e ainda não foram criados. Este guia contém somente o necessário para a pós-instalação.

<a id="indice"></a>
## Índice

- [1. Preparação e decisões](#preparacao)
- [2. Base Aurora e DX](#base)
- [3. Aplicativos e terminal](#aplicativos)
- [4. Opcionais separados](#opcionais)
- [5. Validação e registro](#validacao)

<a id="preparacao"></a>
## 1. Preparação e decisões

### Política do projeto

- Priorizar Flatpak para aplicativos gráficos, Homebrew para ferramentas de terminal e containers para ambientes isolados. Essa é a divisão proposta pela documentação do Aurora. [web:17][web:30]
- Adotar Flatpaks no escopo `system`, conforme a instalação atual. Verificar também `user` antes de instalar para evitar uma segunda cópia.
- Não misturar Flatpak, AppImage e Homebrew para o mesmo aplicativo sem uma razão explícita.
- Não executar todos os comandos do ujust como uma lista de instalação. Muitos são diagnósticos, alternâncias de configuração ou ações de manutenção.
- Não executar os scripts personalizados com `sudo bash`.
- Fazer backup dos arquivos pessoais e das configurações antes de mudanças.
- Preservar o canal atual do sistema. A máquina desta sessão usa `aurora-dx:stable`; isso não deve ser aplicado cegamente a outra máquina.

### Estado desta máquina

Este estado foi informado na conversa; não substitui uma nova verificação no computador.

| Item | Situação conhecida |
|---|---|
| Aurora DX stable | Confirmado pelo banner |
| Aurora CLI | Executado; fórmulas Homebrew listadas |
| Aurora Fonts | 11 fontes listadas no Homebrew |
| Flatpaks padrão do Aurora | Instalador executado |
| Podman Desktop, Embellish, Dev Toolbox | Confirmados pelo usuário |
| Chrome e Gear Lever | Presentes na lista Flatpak enviada |
| VS Code e LM Studio | Presentes via Flatpak; não aparecem entre os casks enviados |
| Node.js | Ainda precisa ser verificado |
| Dev Container CLI | Não encontrado no PATH; decisão: não instalar agora |
| DevPod | Decisão: não instalar agora; presença ainda não confirmada |
| Coleção full-desktop | Decisão: não instalar |
| Coleção ide completa | Não instalar automaticamente |

### Arquivos personalizados

Layout sugerido, para respeitar o caminho esperado pelo instalador Flatpak:

```text
aurora-pos-instalacao/
├── docs/
├── scripts/
│   ├── install-flatpaks.sh
│   └── personalize-aurora-terminal-2.sh
├── config/
│   └── flatpaks.list
└── logs/
```

O `install-flatpaks.sh` procura `config/flatpaks.list` na pasta pai de onde o script está salvo. O catálogo não foi anexado nesta sessão: a lista completa de aplicativos continua pendente. Não inventar nem instalar esse catálogo sem revisão. [file:206]

O arquivo recebido do terminal chama-se `personalize-aurora-terminal-2.sh`; o roteiro mantém esse nome. A ajuda interna menciona outro nome, mas isso não muda o nome real do anexo. [file:207]

Validação realizada para este documento: ambos os anexos passaram em `bash -n` no ambiente de análise. Isso confirma sintaxe Bash, não execução correta no Aurora. Nenhum instalador foi executado e nenhum arquivo anexado foi modificado.

### Diagnóstico inicial

```bash
cat /etc/os-release
rpm-ostree status
ujust --list
command -v brew
flatpak remotes --system
flatpak remotes --user
```

Usamos `rpm-ostree status` porque corresponde ao sistema mostrado nesta sessão. Se uma edição futura usar outro backend ou o comando estiver ausente, confirmar a edição antes de substituir comandos.

Para examinar uma receita antes de executá-la:

```bash
ujust -n aurora-cli
```

O `-n` mostra os comandos da receita sem executá-la; não é uma simulação completa dos efeitos internos de cada programa. Evite usar o menu como diagnóstico se houver risco de selecionar uma receita sem querer. [web:17]

[Voltar ao índice](#indice)

<a id="base"></a>
## 2. Base Aurora e DX

### Passo 1 — Atualização inicial

```bash
ujust update
```

Atualiza o sistema, Flatpaks e fórmulas Homebrew. Aguarde o término e leia possíveis falhas. Não repetir separadamente `brew upgrade` e `flatpak update` como etapa obrigatória deste roteiro. [web:17]

Se houver atualização da imagem ou pedido de reinicialização, salve seu trabalho e execute:

```bash
systemctl reboot
```

Depois de voltar, confira:

```bash
rpm-ostree status
```

### Passo 2 — Confirmar ou ativar DX

Leia a imagem mostrada por `rpm-ostree status`. Se já estiver usando uma imagem `aurora-dx`, pule a ativação.

Somente para uma instalação Aurora comum que você deseja converter para DX:

```bash
ujust devmode
```

Siga as instruções e reinicie quando solicitado. Não execute `devmode` indiscriminadamente: ele alterna entre Aurora e DX, não é um comando que sempre liga DX. [web:17][web:30]

### Passo 3 — Permissões de desenvolvimento

Se você vai usar Docker, Incus, libvirt/virtualização ou dispositivos seriais:

```bash
ujust dx-group
```

Saia da sessão e entre novamente, ou salve seu trabalho e reinicie:

```bash
systemctl reboot
```

Validação:

```bash
id -nG
```

A receita adiciona grupos de desenvolvimento, como `docker`, `incus-admin`, `libvirt` e `dialout`, conforme a versão. Associe apenas usuários confiáveis: esses grupos concedem acesso privilegiado a recursos. Não são todos necessários apenas para usar Podman rootless. [web:17][web:30]

### Passo 4 — Aurora CLI

```bash
ujust aurora-cli
```

Instala a seleção de ferramentas modernas de terminal do Aurora. Na máquina atual, esta etapa já foi realizada. A documentação também prevê repetir a receita para obter ferramentas adicionadas ao conjunto; isso pode instalar novos itens. [web:31]

Validação:

```bash
brew list --formula
command -v starship
command -v zoxide
command -v rg
command -v bat
```

Se uma ferramenta estiver ausente, confira o Brewfile local e a saída do instalador. A lista pode mudar entre versões.

### Passo 5 — Fontes

```bash
ujust aurora-fonts
```

`aurora-fonts` é o alias de `install-fonts` mostrado no menu desta máquina. Execute apenas um deles.

Validação:

```bash
brew list --cask | grep -i font
```

No Konsole, selecione uma fonte instalada, por exemplo JetBrains Mono Nerd Font, no perfil utilizado. A instalação das fontes não implica que todas sejam selecionadas automaticamente. Evite reinstalar as mesmas fontes pelo Embellish sem necessidade.

### Passo 6 — Flatpaks padrão

```bash
ujust install-system-flatpaks
```

Instala os Flatpaks padrão do Aurora, útil especialmente após rebase ou quando há aplicativos básicos ausentes. Não substitui nosso catálogo personalizado. [web:17]

Validação:

```bash
flatpak list --app --system
flatpak list --app --user
```

Extras DX esperados no Brewfile enviado:

```bash
for app in io.podman_desktop.PodmanDesktop io.github.getnf.embellish me.iepure.devtoolbox; do
  if flatpak info --system "$app" >/dev/null 2>&1; then
    printf '[INSTALADO] %s\n' "$app"
  else
    printf '[NÃO ENCONTRADO NO SYSTEM] %s\n' "$app"
  fi
done
```

Esses três aplicativos já foram confirmados nesta máquina. A presença de um Brewfile DX separado não garante que qualquer chamada sem argumentos processe esse arquivo: se algum item faltar, examine `ujust -n install-system-flatpaks` e os parâmetros da receita local.

`Using` indica reutilização de uma dependência encontrada; `Installing` indica uma tentativa de instalação. O total do Bundle não é o número de programas novos. O Bundle também pode atualizar pacotes existentes. Essa detecção não é uma auditoria universal entre Flatpak, Homebrew e AppImage. [web:72]

[Voltar ao índice](#indice)

<a id="aplicativos"></a>
## 3. Aplicativos e terminal

### Passo 7 — Node.js

Primeiro verificar:

```bash
command -v node
command -v npm
brew list --formula
```

Se `node` for encontrado:

```bash
node --version
npm --version
type -a node
```

Você já tem `mise` instalado. Se Node estiver gerenciado por ele ou por um projeto, não adicionar outra instalação sem decidir qual método será utilizado.

Para uma instalação simples pelo Homebrew, somente se Node estiver ausente e esse for o método escolhido:

```bash
brew install node
```

Esse é o comando publicado pela fórmula oficial. A fórmula acompanha o canal oferecido pelo Homebrew; não presumir que seja a versão LTS exigida por todos os projetos. [web:230]

### Passo 8 — Gear Lever

Verificar nos dois escopos:

```bash
flatpak info --system it.mijorus.gearlever
flatpak info --user it.mijorus.gearlever
```

Se ambos informarem ausência e o Flathub estiver configurado no system:

```bash
flatpak install --system flathub it.mijorus.gearlever
```

Abrir o Gear Lever e integrar somente AppImages realmente necessárias. Ele organiza arquivos AppImage e cria entradas no menu; também pode manter versões lado a lado. Não baixar um AppImage de um aplicativo já mantido em Flatpak sem motivo. [web:227]

### Passo 9 — Plasma Drawer

Etapa de interface separada das instalações de pacotes.

O nome “Plasma Drawer” ainda precisa ser associado ao componente exato, sua fonte e a versão do Plasma. Não registrar um caminho de menu ou comando de instalação inventado. Até essa identificação, manter esta etapa como pendente e preservar o painel atual.

### Passo 10 — Nosso terminal

Na pasta onde está o script anexado:

```bash
bash -n personalize-aurora-terminal-2.sh
bash personalize-aurora-terminal-2.sh --dry-run
```

O modo `--dry-run` informa ferramentas ausentes e encerra antes da instalação e aplicação das configurações. [file:207]

> Bloqueio de qualidade: antes da execução normal, revisar a versão anexada. A sintaxe passa, mas existem detalhes funcionais pendentes.

- `install_one_formula` está definida duas vezes.
- `--change-shell` é reconhecido, mas a variável não é utilizada para trocar o shell na versão anexada.
- Arquivos de configuração existentes são preservados; portanto, rodar o script pode não aplicar a personalização desejada sobre uma configuração anterior.
- A chamada usada para validar vários arquivos Zsh precisa ser revisada para garantir verificação individual.

Depois de revisar esses pontos e conferir a simulação, o comando previsto é:

```bash
bash personalize-aurora-terminal-2.sh
```

Não executar com `sudo` nem usar `--yes` nesta primeira aplicação. O script oferece instalação de ferramentas ausentes, baixa plugins e cria configurações/backups. `--offline` impede Homebrew e downloads, mas ainda pode escrever configurações: não equivale a uma simulação. [file:207]

Abrir uma nova sessão de terminal e validar o carregamento de Zsh/Starship. Não trocar o shell de login até testar o resultado.

### Passo 11 — Google Chrome

```bash
flatpak info --system com.google.Chrome
flatpak info --user com.google.Chrome
```

Se ausente nos dois escopos:

```bash
flatpak install --system flathub com.google.Chrome
```

Nesta máquina já aparece como Flatpak system. Não adicionar RPM, cask ou AppImage paralelo sem necessidade. Se Chrome já constar no catálogo personalizado, deixar sua instalação a cargo de apenas uma etapa.

### Passo 12 — Catálogo Flatpak próprio

Pré-requisito: disponibilizar e revisar `config/flatpaks.list`. A lista não foi anexada; não podemos documentar seus aplicativos ainda. [file:206]

Com o layout apresentado e a partir da raiz do projeto:

```bash
bash -n scripts/install-flatpaks.sh
FLATPAK_SCOPE=system bash scripts/install-flatpaks.sh --check
```

`--check` e `--status` consultam o catálogo, mas o script cria registros em `logs`. Não instalam aplicativos. O script verifica ambos os escopos, pula IDs encontrados e marca instalações em `user` e `system` como duplicadas; não detecta uma edição Homebrew ou AppImage do mesmo programa. [file:206]

Depois de revisar o status:

```bash
FLATPAK_SCOPE=system bash scripts/install-flatpaks.sh --install
```

Selecionar somente blocos/aplicativos desejados e ler a confirmação. Não usar `--all` como padrão. Se o remoto Flathub não estiver no escopo system, corrigir isso conscientemente antes de prosseguir, sem criar remotos duplicados.

### Passo 13 — Containers

```bash
command -v podman
podman --version
podman ps
flatpak info --system io.podman_desktop.PodmanDesktop
```

A documentação DX inclui Podman e também Docker com integração de desenvolvimento. Não instalar outro motor apenas porque existe um comando no roteiro. DevPod e Dev Container CLI ficam fora desta pós-instalação, conforme decisão do usuário. [web:30]

O VS Code Flatpak também pode coexistir com uma edição da imagem DX. Nossa lista Homebrew não prova ausência de uma edição RPM: conferir `type -a code` e a imagem antes de declarar que não há duplicidade. Não remover pacotes da base automaticamente. [web:17][web:30]

[Voltar ao índice](#indice)

<a id="opcionais"></a>
## 4. Opcionais separados

### bbrew — consulta seletiva

Esta é uma seção independente; bbrew não será executado automaticamente no roteiro.

Consultar as listas locais:

```bash
ls -1 /usr/share/ublue-os/homebrew/
cat /usr/share/ublue-os/homebrew/ai-tools.Brewfile
```

Verificar dependências de uma coleção local conhecida sem instalar:

```bash
brew bundle check --file=/usr/share/ublue-os/homebrew/ai-tools.Brewfile --verbose
```

A verificação pode retornar código diferente de zero se faltarem dependências; isso não significa que instalou algo. Brewfiles são código Ruby: só examinar/executar arquivos de fonte confiável. [web:72]

| Coleção | Resumo | Decisão do roteiro |
|---|---|---|
| `ai-tools` | Agentes de código, utilitários LLM e interfaces de IA | Revisar; LM Studio cask pode coexistir com seu Flatpak |
| `artwork` | Coleção visual; conteúdo exato depende do arquivo | Opcional, ler antes |
| `cli` | Utilitários modernos de terminal | Conferir cobertura do Aurora CLI |
| `cncf` | Ferramentas cloud-native | Somente para demanda específica |
| `experimental-ide` | Coleção experimental de ferramentas de desenvolvimento | Fora do padrão; revisar arquivo |
| `fonts` | Fontes de programação/Nerd Fonts | Já tratada por aurora-fonts |
| `full-desktop` | 11 aplicativos KDE no arquivo enviado | Não instalar, decisão do usuário |
| `ide` | Vários editores, JetBrains Toolbox e Dev Container CLI | Não instalar o conjunto inteiro |
| `k8s-tools` | Ferramentas Kubernetes | Somente ao iniciar esse estudo |
| `swift` | Ferramentas da linguagem Swift | Somente se houver necessidade |

Os arquivos `system-flatpaks.Brewfile` e `system-dx-flatpaks.Brewfile` são conjuntos padrão, tratados na etapa da base; sua presença na pasta não significa que são todas opções do menu bbrew.

Para abrir o seletor quando realmente quiser instalar uma coleção:

```bash
ujust bbrew
```

A seleção pode iniciar a aplicação de toda a coleção. Não presumir uma tela adicional de confirmação. Se cancelar e aparecer `nothing selected` com código 1, como na captura enviada, isso indica que nenhuma coleção foi escolhida nessa execução.

### ONLYOFFICE — opcional

Para documentos, planilhas e apresentações locais, considerar ONLYOFFICE Desktop Editors, não confundir com produtos de servidor Docs/DocSpace. [web:228][web:232]

```bash
flatpak info --system org.onlyoffice.desktopeditors
flatpak info --user org.onlyoffice.desktopeditors
```

Somente se ausente e desejado:

```bash
flatpak install --system flathub org.onlyoffice.desktopeditors
```

Se for incluído no nosso catálogo, usar somente aquela etapa. Instalar uma única edição e testar abertura/salvamento de documentos.

### LinuxToys — manual e opcional

O projeto declara compatibilidade com distribuições Atomic baseadas em Fedora, incluindo Aurora. Também disponibiliza AppImage. Isso não torna todas as ações internas necessárias para o nosso roteiro. [web:229]

Preferência deste guia: avaliar a AppImage oficial e integrá-la com Gear Lever, sem adicionar camadas RPM por padrão. Conferir a versão e compatibilidade antes de executar.

Não incorporar `curl | bash`, instalação por COPR/rpm-ostree ou otimizações em massa ao fluxo automático. Cada recurso deve ser escolhido conscientemente. Documentação: [LinuxToys](https://linux.toys/index.pt-BR.html) e [código oficial](https://github.com/psygreg/linuxtoys).

### Fora da execução padrão

| Comando | Motivo |
|---|---|
| `ujust powerwash` | Restauração experimental; risco aos dados/configurações |
| `ujust rebase-helper` | Troca imagem/canal ou versão; não é limpeza |
| `ujust clean-system` | Pode limpar containers, volumes e deployments |
| `ujust toggle-tpm2` | Altera desbloqueio de disco criptografado |
| `ujust toggle-iwd` | Altera backend de Wi-Fi |
| `ujust enroll-secure-boot-key` | Somente quando a configuração de Secure Boot exigir |
| `ujust toggle-updates` | Alterna estado; não garante que atualizações fiquem ligadas |
| `ujust device-info` | Envia informações a um pastebin; não é diagnóstico estritamente local |

Consulte a documentação ujust futura antes de usar essas ações. A documentação oficial confirma os efeitos de limpeza, rede, TPM e envio ao pastebin. [web:17]

[Voltar ao índice](#indice)

<a id="validacao"></a>
## 5. Validação e registro

### Conferência final

```bash
rpm-ostree status
id -nG
brew list
flatpak list --app --system
flatpak list --app --user
podman ps
```

Para investigar um programa que pode existir em mais de uma origem:

```bash
type -a code
brew list --cask
rpm -qa | grep -Ei 'code|codium|lm-studio'
```

Essas consultas oferecem pistas, não uma detecção universal. Flatpaks normalmente não expõem executáveis comuns no PATH. Uma biblioteca repetida ou versões diferentes de runtime Flatpak não são automaticamente aplicativos duplicados.

### Checklist de conclusão

- [ ] Imagem e canal do Aurora confirmados.
- [ ] Atualização concluída; reinicialização feita quando necessária.
- [ ] DX confirmado sem alternância indevida.
- [ ] Grupos de desenvolvimento revisados e nova sessão iniciada.
- [ ] Aurora CLI e fontes verificados.
- [ ] Flatpaks padrão e extras DX verificados.
- [ ] Método de Node decidido e versão validada, ou etapa adiada.
- [ ] Gear Lever verificado.
- [ ] Plasma Drawer identificado antes de alteração.
- [ ] Script de terminal revisado, simulado e aplicado somente se aprovado.
- [ ] Catálogo flatpaks.list disponibilizado e revisado.
- [ ] Aplicativos adicionais instalados seletivamente.
- [ ] bbrew não executado em massa.
- [ ] DevPod/devcontainer continuam opcionais, sem instalação nesta etapa.
- [ ] ONLYOFFICE e LinuxToys avaliados ou adiados.
- [ ] Nenhum comando de restauração/limpeza destrutiva usado.

### Salvar inventário

O bloco abaixo grava um relatório local; não envia dados a serviços externos. Logs podem conter nome de usuário, máquina e caminhos: revisar antes de compartilhar.

```bash
mkdir -p "$HOME/aurora-pos-instalacao/logs"
{
  date
  cat /etc/os-release
  rpm-ostree status
  id -nG
  brew list
  flatpak list --app --system
  flatpak list --app --user
  podman --version
} > "$HOME/aurora-pos-instalacao/logs/inventario-$(date +%Y%m%d-%H%M%S).txt" 2>&1
```

### Critérios de manutenção

Use `ujust update` para a atualização integrada; não acrescente limpeza destrutiva à mesma rotina. Consulte os comandos locais com `ujust --list` e receitas com `ujust -n NOME` porque as receitas podem mudar. [web:17]

Documentação-base: [Uso básico do Aurora](https://docs.getaurora.dev/guides/basic-usage/#curated-tool-bundles), [Ferramentas Aurora CLI](https://docs.getaurora.dev/guides/aurora-cli/#included-tools) e [Aurora DX](https://docs.getaurora.dev/dx/aurora-dx-intro/).

Os dois links Aurora fornecidos estavam unidos em uma única URL; aqui foram separados em endereços utilizáveis.

[Voltar ao índice](#indice)
