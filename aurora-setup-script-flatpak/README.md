# Aurora Setup Script Flatpak

Projeto para organizar e automatizar a instalação de aplicativos Flatpak no Aurora Linux, seguindo o padrão utilizado pelo Bazaar e preservando o sistema imutável.

O instalador lê o catálogo `config/flatpaks.list`, verifica os escopos `user` e `system`, preserva aplicativos já instalados e instala somente os aplicativos ausentes.

## Índice

- [Objetivo](#objetivo)
- [Estrutura](#estrutura)
- [Requisitos](#requisitos)
- [Permissão de execução](#permissão-de-execução)
- [Teste seguro](#teste-seguro)
- [Instalação completa](#instalação-completa)
- [Menu interativo](#menu-interativo)
- [Aplicativos disponíveis](#aplicativos-disponíveis)
- [Espaço em disco](#espaço-em-disco)
- [Logs](#logs)
- [Como repetir após falha](#como-repetir-após-falha)
- [Comandos úteis](#comandos-úteis)
- [Limitações atuais](#limitações-atuais)
- [Boas práticas](#boas-práticas)

## Objetivo

O projeto foi criado para o Aurora Linux e usa Flatpak/Flathub para aplicativos gráficos.

Princípios:

- não usar `rpm-ostree` para aplicativos gráficos comuns;
- não usar `dnf` diretamente no host Aurora para esse objetivo;
- não reinstalar aplicativos já instalados;
- verificar `user` e `system` antes de instalar;
- seguir o padrão predominante do Bazaar para novos aplicativos;
- manter permissões Flatpak originais;
- não usar `sudo` automaticamente;
- permitir repetir a execução depois de uma interrupção;
- registrar o resultado em log.

## Estrutura

Exemplo do projeto:

```text
/var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/
├── README.md
├── config/
│   └── flatpaks.list
├── scripts/
│   └── install-flatpaks.sh
└── logs/
```

O catálogo fica em:

```text
/var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/config/flatpaks.list
```

O instalador fica em:

```text
/var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/scripts/install-flatpaks.sh
```

## Requisitos

- Aurora Linux funcionando;
- Flatpak instalado;
- Flathub configurado;
- conexão com a internet para instalar aplicativos;
- espaço livre suficiente;
- Bash;
- permissão de execução no script.

Verificar o ambiente:

```bash
flatpak --version
flatpak remotes
uname -m
```

O script verifica o Aurora, o Flatpak e o Flathub antes de continuar.

## Permissão de execução

Entre na pasta do projeto:

```bash
cd /var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/
```

Conceda permissão ao script:

```bash
chmod +x scripts/install-flatpaks.sh
```

Confirme:

```bash
ls -l scripts/install-flatpaks.sh
```

A saída deve conter `x`, por exemplo:

```text
-rwxr-xr-x ... scripts/install-flatpaks.sh
```

Também é possível executar pelo Bash sem a permissão de execução:

```bash
bash scripts/install-flatpaks.sh --check
```

Entretanto, o modo recomendado é manter o arquivo executável e usar `./`.

## Teste seguro

O modo de diagnóstico não instala nem remove aplicativos.

A partir da raiz do projeto:

```bash
cd /var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/
./scripts/install-flatpaks.sh --check
```

Esse teste:

- detecta o Aurora;
- confirma o Flathub;
- lê o catálogo;
- verifica cada aplicativo;
- identifica o escopo `user` ou `system`;
- mostra a versão instalada;
- identifica aplicativos ausentes;
- cria um log;
- não faz alterações.

Exemplo de resultado:

```text
[INSTALADO] Google Chrome (com.google.Chrome) system versão=154.0.8037.97-1
[INSTALADO] Brave Browser (com.brave.Browser) system versão=1.96.61
[AUSENTE] Discord (com.discordapp.Discord)
```

## Instalação completa

Para abrir o instalador interativo:

```bash
cd /var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/
./scripts/install-flatpaks.sh --install
```

Também é possível executar sem argumento:

```bash
./scripts/install-flatpaks.sh
```

No menu principal:

```text
[1] browsers
[2] development
[3] media
[4] productivity
[5] gaming
[6] graphics
[7] diagnostics
[8] ai
[9] communication
[A] Instalar todos os blocos
[S] Ver status
[Q] Sair
```

Para instalar tudo:

```text
Escolha: a
```

O script então:

1. verifica os aplicativos existentes;
2. preserva o que já estiver instalado;
3. calcula o que está ausente;
4. mostra o escopo escolhido;
5. pede confirmação;
6. instala os ausentes um por vez;
7. continua depois de uma falha individual;
8. gera o resumo final.

O comando equivalente sem abrir o menu é:

```bash
./scripts/install-flatpaks.sh --all
```

A opção `--all` ainda respeita a detecção do escopo e pede confirmação.

## Menu interativo

Dentro de qualquer bloco, a opção `[1]` significa instalar todos os aplicativos daquele bloco.

Exemplo:

```text
Bloco: development

[1] Instalar todos
[2] Visual Studio Code
[3] Insomnia
[4] Postman
[5] pgAdmin 4
[6] Antares SQL
[0] Voltar
```

A opção `[1]` instala todos os aplicativos do bloco, mas ignora os que já estiverem instalados.

## Aplicativos disponíveis

O catálogo atual contém os seguintes blocos.

### Navegadores

- Google Chrome — `com.google.Chrome`.
- Brave Browser — `com.brave.Browser`.

### Desenvolvimento

- Visual Studio Code — `com.visualstudio.code`.
- Insomnia — `rest.insomnia.Insomnia`.
- Postman — `com.getpostman.Postman`.
- pgAdmin 4 — `org.pgadmin.pgadmin4`.
- Antares SQL — `it.fabiodistasio.AntaresSQL`.

### Vídeo e multimídia

- VLC — `org.videolan.VLC`.
- OBS Studio — `com.obsproject.Studio`.
- HandBrake — `fr.handbrake.ghb`.
- fre:ac — `org.freac.freac`.
- Kdenlive — `org.kde.kdenlive`.

### Produtividade

- Bitwarden — `com.bitwarden.desktop`.
- Obsidian — `md.obsidian.Obsidian`.
- Zotero — `org.zotero.Zotero`.
- JDownloader — `org.jdownloader.JDownloader`.

### Jogos

- Steam — `com.valvesoftware.Steam`.
- Heroic Games Launcher — `com.heroicgameslauncher.hgl`.

### Gráficos

- GIMP — `org.gimp.GIMP`.
- Camera Controls — `hu.irl.cameractrls`.

### Diagnóstico

- Corex — `io.github.edewin.corex`.
- CPU-X — `io.github.thetumultuousunicornofdarkness.cpu-x`.
- GPU-Viewer — `io.github.arunsivaramanneo.GPUViewer`.
- KDiskMark — `io.github.jonmagon.kdiskmark`.
- Aurynk — `io.github.IshuSinghSE.aurynk`.

### Inteligência artificial

- LM Studio — `ai.lmstudio.lm-studio`.
- Buzz — `io.github.chidiwilliams.Buzz`.

O Vibe ainda não está ativo no catálogo porque o ID Flatpak precisa ser confirmado.

### Comunicação

- Discord — `com.discordapp.Discord`.
- ZapZap — `com.rtosta.zapzap`.

## Espaço em disco

O Flatpak precisa de espaço para baixar, extrair e finalizar a instalação. O tamanho exibido do aplicativo não é necessariamente o espaço temporário total exigido.

Verifique o espaço antes de instalar:

```bash
df -h /var
df -h /var/home
```

O Buzz pode exigir aproximadamente 9,8 GB livres durante a transação, mesmo quando o tamanho exibido do aplicativo é menor. Aplicativos que usam modelos locais, como Buzz e LM Studio, também podem consumir espaço adicional depois da instalação.

Se uma instalação falhar por espaço:

1. libere espaço;
2. verifique novamente com `df -h`;
3. execute o instalador novamente;
4. deixe o script pular o que já foi instalado.

Não remova manualmente arquivos de `/var/lib/flatpak`.

Para remover runtimes não utilizados, revise primeiro a lista:

```bash
flatpak uninstall --system --unused
```

## Logs

Cada execução cria um arquivo em:

```text
/var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/logs/
```

Exemplo:

```text
logs/flatpaks-20261006-151626.log
```

O log registra:

- sistema detectado;
- Flathub encontrado;
- catálogo utilizado;
- aplicativos já instalados;
- aplicativos instalados;
- falhas;
- resumo final.

## Como repetir após falha

Se a internet cair, o computador for desligado ou faltar espaço, não é necessário reinstalar tudo.

Execute novamente:

```bash
cd /var/home/dan/repos/aurora-terminal-personalization/aurora-setup-script-flatpak/
./scripts/install-flatpaks.sh --install
```

Escolha:

```text
[A] Instalar todos os blocos
```

O script verificará o estado atual e pulará os aplicativos já instalados. Ele tentará novamente apenas os ausentes.

## Comandos úteis

Ver todos os Flatpaks do sistema:

```bash
flatpak list --system --app --columns=application,version,name
```

Ver Flatpaks do usuário:

```bash
flatpak list --user --app --columns=application,version,name
```

Verificar um aplicativo:

```bash
flatpak info --system com.google.Chrome
```

Executar um aplicativo:

```bash
flatpak run com.google.Chrome
```

Atualizar Flatpaks do sistema:

```bash
flatpak update --system
```

Verificar possíveis problemas sem reparar:

```bash
flatpak repair --dry-run
```

Consultar a ajuda do instalador:

```bash
./scripts/install-flatpaks.sh --help
```

## Limitações atuais

- O escopo predominante é detectado pela quantidade de aplicativos existentes.
- Se houver empate entre `user` e `system`, o script pergunta qual escopo usar.
- O script não modifica permissões Flatpak automaticamente.
- O ID do Vibe ainda precisa ser confirmado.
- Avisos de runtimes fora de suporte, como o runtime 24.08 do Postman, precisam ser avaliados separadamente.
- O script instala aplicativos, mas não configura contas, modelos de IA ou bibliotecas de jogos.
- REAPER, plugins de áudio, Paperless-ngx, servidores de banco de dados e OpenRazer estão fora deste instalador.

## Boas práticas

- Execute `--check` antes da primeira instalação.
- Leia o resumo antes de confirmar.
- Mantenha espaço livre no armazenamento.
- Não execute o script como root.
- Não use `sudo` para iniciar o script.
- Não apague manualmente arquivos do repositório Flatpak.
- Faça backup dos dados importantes.
- Use o Bazaar ou Flatpak para atualizar os aplicativos.
- Consulte os logs quando uma instalação falhar.

## Versão

Versão atual do instalador:

```text
2.0.0
```

O catálogo e o script podem evoluir conforme novos aplicativos forem validados no Aurora.
