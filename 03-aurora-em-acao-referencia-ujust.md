# Aurora em Ação — Referência completa do ujust

Documento 3 de 3 · Projeto Aurora Pronto  
Versão 1.0 · 7 de outubro de 2026  
Projeto de Marcos Daniel Gomes Dantas

Catálogo de referência das receitas `ujust` disponíveis no Aurora desta sessão. O documento explica finalidade, efeitos, nível de cautela e validação. A lista do terminal é a autoridade para a imagem instalada: receitas podem ser adicionadas, removidas, renomeadas ou alteradas entre versões.

> Regra do projeto: consulte primeiro com `ujust --choose`, `ujust --list` ou `ujust -n NOME`. Não execute receitas de alteração do sistema apenas para conhecê-las.

<a id="indice"></a>
## Índice

- [1. Como ler esta documentação](#como-ler)
- [2. Diagnóstico e consulta](#diagnostico)
- [3. Atualização e manutenção](#atualizacao)
- [4. Aurora DX e desenvolvimento](#dx)
- [5. Aplicativos e coleções](#aplicativos)
- [6. Logs, hardware e energia](#hardware)
- [7. Rede, TPM e Secure Boot](#seguranca)
- [8. Boot, imagem e recuperação](#recuperacao)
- [9. Personalização](#personalizacao)
- [10. Matriz de decisão](#matriz)
- [11. Validação final](#validacao)

<a id="como-ler"></a>
## 1. Como ler esta documentação

### O que é ujust

No Aurora, `ujust` é um alias para o executor de tarefas `just`. As receitas são atalhos para scripts e sequências de comandos mantidos pelo projeto; algumas são conveniências e outras automatizam configurações mais complexas. O próprio Aurora recomenda usar `ujust --choose` para navegar e `ujust -n NOME` para inspecionar uma receita antes de executá-la. [web:17]

`ujust` não é:

- um gerenciador de pacotes equivalente a `dnf`;
- um comando que sempre instala um programa;
- uma garantia de que todas as receitas são permanentes;
- uma transação que possa ser desfeita com um único comando.

### Níveis de cautela

| Nível | Significado |
|---|---|
| Consulta | Mostra informações; não deveria alterar o sistema. Ainda pode enviar dados se a descrição disser isso. |
| Seguro/baixo | Configura uma ferramenta ou instala conteúdo selecionado, com efeitos normalmente reversíveis. |
| Atenção | Altera grupos, rede, serviços, boot ou comportamento de segurança. |
| Alto | Pode trocar a imagem, mexer em criptografia, limpar dados ou restaurar o dispositivo. |

A classificação é orientação operacional, não uma garantia contra bugs. Leia a receita local.

### Preparação mínima

```bash
ujust --choose
ujust --list
ujust -n NOME_DO_COMANDO
```

Se a versão não aceitar `--list`, use:

```bash
ujust --choose
```

Para registrar a lista atual:

```bash
ujust --list > "$HOME/aurora-ujust-lista-$(date +%Y%m%d-%H%M%S).txt"
```

Essa lista é específica do deployment atual. Não copiar cegamente esta documentação para outra variante, como NVIDIA, ou para outra edição do Aurora.

[Voltar ao índice](#indice)

<a id="diagnostico"></a>
## 2. Diagnóstico e consulta

### `ujust --choose`

```bash
ujust --choose
```

Abre a interface para visualizar as receitas disponíveis e, dependendo da escolha, executá-las. É útil para descoberta, mas não é um modo somente leitura em toda a interface.

Use setas e `Esc`/cancelamento para sair sem escolher. Se aparecer `nothing selected` e código 1, isso geralmente significa que nenhuma receita foi selecionada; não é uma instalação parcial. Se a execução já começou, analise a saída antes de assumir que nada mudou.

### `ujust -n NOME`

```bash
ujust -n update
ujust -n bbrew
ujust -n install-system-flatpaks
```

Mostra os comandos que a receita pretende executar sem executar a receita. É o primeiro passo recomendado para entender uma ação. Comandos internos podem ter efeitos que só ficam claros quando interpretados; não tratar como sandbox de código não confiável.

### `ujust device-info`

```bash
ujust device-info
```

Coleta informações do dispositivo, lista de Flatpaks e estado do sistema e envia o resultado a um pastebin, retornando uma URL. Útil para pedir ajuda, mas pode expor detalhes do hardware e do ambiente. Revisar o conteúdo antes de compartilhar. [web:17]

Nível: **consulta com envio externo**.

### `ujust check-local-overrides`

```bash
ujust check-local-overrides
```

Mostra arquivos que diferem entre `/usr/etc` e `/etc`, ajudando a identificar configurações locais que podem interferir em atualizações.

Nível: consulta.

### `ujust changelogs` e `ujust changelogs-fedora`

```bash
ujust changelogs
ujust changelogs-fedora
```

Exibem mudanças relacionadas às atualizações. São úteis antes ou depois de atualizar, principalmente quando uma alteração de comportamento aparece.

Nível: consulta.

[Voltar ao índice](#indice)

<a id="atualizacao"></a>
## 3. Atualização e manutenção

### `ujust update` / `ujust upgrade`

```bash
ujust update
```

O alias `upgrade` também aparece em algumas imagens. A receita atualiza o sistema Aurora, Flatpaks e pacotes Homebrew, conforme a documentação de uso básico. [web:17]

Fluxo seguro:

```bash
ujust -n update
ujust update
rpm-ostree status
```

Reinicie se a atualização da imagem pedir:

```bash
systemctl reboot
```

Nível: baixo, mas pode mudar a imagem do sistema e atualizar vários aplicativos.

### `ujust toggle-updates` / `ujust auto-update`

```bash
ujust toggle-updates
```

Alterna as atualizações automáticas. `auto-update` é alias mostrado em algumas listas.

Use somente depois de decidir se deseja atualizações automáticas. Desativar atualizações por muito tempo aumenta a manutenção manual e pode deixar correções de segurança pendentes.

Nível: atenção.

Validação: consulte o estado no Aurora Preferences e confira novamente a receita local.

### `ujust clean-system`

```bash
ujust clean-system
```

Limpa recursos não utilizados, incluindo containers/volumes, runtimes Flatpak e deployments antigos, conforme a documentação do Aurora. [web:17]

Antes de usar:

```bash
podman ps -a
podman volume ls
flatpak list --runtime
rpm-ostree status
ujust -n clean-system
```

Não usar como primeira tentativa de liberar espaço. Volumes de containers podem conter dados de bancos e projetos.

Nível: **atenção/alto**, dependendo dos dados existentes.

### `ujust benchmark`

```bash
ujust benchmark
```

Executa um benchmark de aproximadamente um minuto usando carga do sistema. Pode aumentar CPU, temperatura, consumo e ruído temporariamente.

Antes:

```bash
uptime
sensors 2>/dev/null || true
```

Não usar durante trabalho importante ou em equipamento com refrigeração problemática.

Nível: baixo, com impacto temporário.

[Voltar ao índice](#indice)

<a id="dx"></a>
## 4. Aurora DX e desenvolvimento

### `ujust devmode` / `ujust toggle-devmode`

```bash
ujust devmode
```

`toggle-devmode` é alias listado em algumas versões. Alterna entre Aurora comum e Aurora DX. A documentação define DX como a experiência para desenvolvimento, com Homebrew, containers, virtualização, VS Code/Dev Containers e Podman. [web:30]

Antes:

```bash
rpm-ostree status
ujust -n devmode
```

Se o sistema já estiver em `aurora-dx`, não execute novamente apenas para confirmar. Uma alternância pode colocar o sistema na imagem oposta.

Nível: **atenção alto**, porque modifica a imagem base e normalmente exige reinicialização.

### `ujust dx-group`

```bash
ujust dx-group
```

Adiciona o usuário a grupos necessários para desenvolvimento, como Docker, `incus-admin`, `libvirt` e `dialout`, segundo a documentação DX. [web:30]

Depois:

```bash
systemctl reboot
```

Validação:

```bash
id -nG
```

Nível: atenção. Grupos de containers/virtualização podem conceder acesso privilegiado a recursos da máquina.

### `ujust aurora-cli`

```bash
ujust aurora-cli
```

Ativa a experiência de terminal do Aurora baseada em Homebrew e instala a seleção curada de ferramentas modernas. A documentação cita ferramentas como Atuin, bat, chezmoi, direnv, eza, fd, GitHub CLI, ripgrep, Starship, tealdeer, zoxide e outras. [web:31]

Validação:

```bash
brew list --formula
command -v starship zoxide rg fd bat eza
```

O Bundle identifica itens que já existem no Homebrew; isso não é detecção cruzada entre Flatpak, AppImage e Homebrew.

Nível: baixo.

### `ujust aurora-fonts` / `ujust install-fonts`

```bash
ujust aurora-fonts
```

Instala fontes selecionadas via Homebrew. O menu desta máquina mostra `aurora-fonts` como alias de `install-fonts`; use somente um deles.

Validação:

```bash
brew list --cask | grep -i '^font-'
```

Nível: baixo. Uma fonte instalada não é automaticamente aplicada ao Konsole ou VS Code.

### `ujust install-system-flatpaks`

```bash
ujust install-system-flatpaks
```

Instala os Flatpaks de sistema definidos pelo Aurora, útil após rebase ou quando o conjunto padrão está ausente. A execução enviada mostrou itens como Flatseal, Bazaar, Warehouse, Mission Center, Podman Desktop, Firefox, Thunderbird e outros, mas a composição depende da imagem. [web:17]

Antes:

```bash
flatpak list --app --system
flatpak list --app --user
ujust -n install-system-flatpaks
```

Nível: baixo, mas pode instalar muitos aplicativos e runtimes.

### `ujust bbrew`

```bash
ujust bbrew
```

Abre o Bold Brew para selecionar Brewfiles curados. Não confundir com `ujust aurora-cli`: o primeiro é um seletor de coleções; o segundo instala a seleção CLI do Aurora. [web:17]

Antes:

```bash
ujust -n bbrew
ls -1 /usr/share/ublue-os/homebrew/
```

Leia o Brewfile e verifique a coleção antes de instalar. Consulte o documento 2, `02-aurora-em-colecoes-referencia-bbrew.md`.

Nível: baixo/atenção, conforme a coleção.

[Voltar ao índice](#indice)

<a id="aplicativos"></a>
## 5. Aplicativos e coleções

### `ujust jetbrains-toolbox` / `ujust install-jetbrains-toolbox`

```bash
ujust install-jetbrains-toolbox
```

Instala o JetBrains Toolbox no diretório do usuário para administrar IDEs JetBrains. O alias `jetbrains-toolbox` também é listado. O Toolbox é o gerenciador; ele não instala todas as IDEs automaticamente. [web:30]

Use somente se desejar IntelliJ IDEA, PyCharm, WebStorm, CLion, DataGrip ou outra IDE JetBrains.

Nível: baixo. Verifique se o Toolbox já existe antes.

### `ujust install-opentabletdriver`

```bash
ujust install-opentabletdriver
```

Instala ou remove/configura o OpenTabletDriver, conforme o fluxo apresentado pela receita. É um driver em modo de usuário para mesas digitalizadoras compatíveis.

Use somente quando houver uma mesa digitalizadora e após conferir compatibilidade. Não executar como parte da instalação geral.

Nível: baixo/atenção, porque altera a configuração de entrada.

### `ujust setup-sunshine`

```bash
ujust setup-sunshine
```

Configura o Sunshine como host de streaming. É usado para transmitir jogos ou o desktop para outro dispositivo, geralmente com um cliente compatível como Moonlight.

Use somente se streaming remoto fizer parte do seu objetivo. Depois, revisar autenticação, portas e exposição na rede local.

Nível: atenção, por habilitar um serviço de rede.

### `ujust cncf`

```bash
ujust cncf
```

Abre o Bold Brew com o conjunto CNCF. A documentação Aurora descreve uma coleção ampla de projetos cloud-native; ela pode incluir Argo, Cilium, Envoy, Flux, Istio, Linkerd e Prometheus, além de ferramentas de Kubernetes. [web:30]

Não selecionar como substituto de `k8s-tools` sem saber o objetivo. CNCF é uma coleção muito mais ampla.

Nível: baixo na abertura, potencialmente atenção durante instalação.

### `ujust install-system-flatpaks` — repetição

Se já executado e todos os aplicativos padrão estiverem presentes, a repetição tende a mostrar `Using` para os itens conhecidos. Ainda assim, a receita pode instalar novos itens adicionados ao Brewfile ou atualizar dependências. Consulte o documento bbrew e use `ujust -n` antes de versões diferentes.

Nível: baixo.

[Voltar ao índice](#indice)

<a id="hardware"></a>
## 6. Logs, hardware e energia

### `ujust bios-info`

```bash
ujust bios-info
```

Mostra fabricante, produto, versão e data da BIOS/UEFI.

Nível: consulta.

### `ujust bios`

```bash
ujust bios
```

Reinicia o computador e tenta entrar na BIOS/UEFI. Salve o trabalho antes: é uma ação de reinicialização imediata.

Nível: baixo, mas interrompe a sessão.

### `ujust device-info`

Já documentado na seção de diagnóstico. Reforço: envia informações para pastebin. Use apenas quando aceitar essa divulgação.

### `ujust logs-this-boot`

```bash
ujust logs-this-boot
```

Exibe mensagens do sistema do boot atual. Para filtrar problemas:

```bash
ujust logs-this-boot | less
```

Não compartilhe logs sem revisar nomes de usuário, caminhos, endereços IP, dispositivos e tokens que possam ter sido impressos por algum serviço.

Nível: consulta.

### `ujust logs-last-boot`

```bash
ujust logs-last-boot
```

Exibe mensagens do boot anterior. Útil depois de uma falha de inicialização, suspensão ou reinicialização.

Nível: consulta.

### `ujust check-idle-power-draw`

```bash
ujust check-idle-power-draw
```

Mede o consumo ocioso usando `powerstat`. Feche aplicativos e aguarde o sistema estabilizar para obter medida útil. Em notebook, compare com a bateria, brilho e rede em condições semelhantes.

Nível: consulta com carga/medição temporária.

### `ujust check-local-overrides`

Já documentado. Use antes de uma investigação de atualização ou configuração local.

### `ujust changelogs` / `changelogs-fedora`

Já documentados. Use para relacionar mudança de comportamento com atualização.

[Voltar ao índice](#indice)

<a id="seguranca"></a>
## 7. Rede, TPM e Secure Boot

### `ujust toggle-tailscale`

```bash
ujust toggle-tailscale
```

Alterna a integração do Tailscale no Aurora. Tailscale cria conectividade VPN entre dispositivos; use apenas se você pretende administrar máquinas ou acessar serviços remotamente.

Depois, revisar dispositivos autorizados, ACLs e exposição dos serviços. Não ativar como requisito geral.

Nível: atenção, por alterar conectividade e potencial acesso remoto.

### `ujust toggle-iwd`

```bash
ujust toggle-iwd
```

Alterna entre IWD e `wpa_supplicant` para o Wi-Fi. A documentação cita possível melhoria de throughput/latência com IWD, mas isso depende do hardware e da rede. [web:17]

Se o Wi-Fi funciona, não alterar. Antes de testar, garanta acesso alternativo e anote o estado atual.

Nível: atenção. Pode interromper a rede e exigir reinicialização/serviço.

### `ujust toggle-tpm2`

```bash
ujust toggle-tpm2
```

Alterna o desbloqueio automático do volume LUKS via TPM 2, opcionalmente com PIN, conforme o fluxo da receita. [web:17]

Não executar sem entender:

- se o disco usa LUKS;
- como está o backup da chave;
- qual é o comportamento em troca de placa/TPM;
- como recuperar o sistema se o TPM não liberar o volume.

Nível: **alto**. Não pertence ao roteiro de pós-instalação padrão.

### `ujust enroll-secure-boot-key`

```bash
ujust enroll-secure-boot-key
```

Registra a chave para módulos NVIDIA/KMOD assinados quando o Secure Boot exige isso. A documentação mostra a senha `universalblue` para o fluxo correspondente. [web:17]

Não executar sem verificar:

```bash
mokutil --sb-state
rpm-ostree status
```

Use somente em uma variante NVIDIA e situação compatível. Não é uma etapa genérica de Aurora.

Nível: alto/atenção.

[Voltar ao índice](#indice)

<a id="recuperacao"></a>
## 8. Boot, imagem e recuperação

### `ujust configure-boot-to-windows`

```bash
ujust configure-boot-to-windows
```

Configura uma entrada de inicialização para o desktop Windows em cenários de dual boot. Use somente depois de confirmar que o Windows existe e que você entende o gerenciador de boot atual.

Antes:

```bash
bootctl status 2>/dev/null || true
lsblk -f
```

Nível: atenção. Não executar em uma máquina sem Windows ou sem necessidade.

### `ujust rebase-helper` / aliases de stream

```bash
ujust rebase-helper
```

A lista desta máquina mostra aliases como `rollback-helper`, `switch-stream` e `switch-streams`. O helper pode trocar entre streams, variantes/imagens e versões anteriores. A documentação recomenda o helper para mudar stream ou imagem. [web:23]

Streams principais:

| Stream | Perfil |
|---|---|
| `stable` | Uso diário e estabilidade; recomendado para a maioria |
| `latest` | Atualizações mais rápidas; pode ter problemas ocasionais |
| `testing` | Pré-lançamento; maior volatilidade |

A máquina do projeto usa `aurora-dx:stable`. Não trocar para `latest` ou `testing` como exercício. Rebasing para uma imagem antiga pode pausar atualizações até voltar a um canal adequado. [web:23]

Antes de usar:

```bash
rpm-ostree status
ujust -n rebase-helper
```

Faça backup e mantenha conexão confiável. Se a intenção for desfazer apenas a última atualização ruim, considere:

```bash
rpm-ostree rollback
```

Isso seleciona o deployment anterior; ainda será necessário reiniciar. Não confundir rollback com rebase para outro canal.

Nível: **alto**.

### `ujust powerwash`

```bash
ujust powerwash
```

Faz restauração de fábrica do dispositivo/sistema conforme implementação atual. É experimental e pode remover configurações, aplicativos e dados dependendo do fluxo.

Não usar no roteiro de pós-instalação, não usar como limpeza e não executar sem backup validado.

Nível: **alto/destrutivo**.

[Voltar ao índice](#indice)

<a id="personalizacao"></a>
## 9. Personalização

### `ujust toggle-user-motd`

```bash
ujust toggle-user-motd
```

Liga ou desliga o banner de boas-vindas mostrado no terminal. Não altera o shell, o prompt, os plugins ou os pacotes.

Nível: baixo.

### `ujust toggle-dinosaurs`

```bash
ujust toggle-dinosaurs
```

Baixa/alterna papéis de parede mensais de dinossauros do ecossistema relacionado. É uma personalização visual; não é necessária para o sistema.

Nível: baixo, com download.

### Relação com o nosso script de terminal

O script `personalize-aurora-terminal-2.sh` não é `ujust`. Ele é um script do projeto e deve ser tratado separadamente:

```bash
bash -n personalize-aurora-terminal-2.sh
bash personalize-aurora-terminal-2.sh --dry-run
```

Só depois de revisar a simulação:

```bash
bash personalize-aurora-terminal-2.sh
```

O script verifica Aurora/Homebrew, pode instalar fórmulas ausentes, baixar plugins e criar backups/configurações Zsh e Starship. Não executá-lo como root. Não confundir `ujust aurora-cli` com a personalização do prompt.

[Voltar ao índice](#indice)

<a id="matriz"></a>
## 10. Matriz de decisão

| Comando | Instala? | Altera sistema? | Reiniciar? | Decisão neste projeto |
|---|---:|---:|---:|---|
| `ujust --choose` | Não por si | Não, se cancelar | Não | Usar para consultar |
| `ujust -n NOME` | Não por si | Não, como receita dry-run | Não | Usar antes de comandos |
| `ujust update` | Atualiza | Sim, imagem/apps | Talvez | Recomendado |
| `ujust dx-group` | Não | Grupos do usuário | Sair/reiniciar | Recomendado para DX |
| `ujust aurora-cli` | Homebrew | Home do usuário | Não | Já realizado |
| `ujust aurora-fonts` | Fontes | Home do usuário | Não | Já realizado |
| `ujust install-system-flatpaks` | Flatpaks | Dados Flatpak | Não normalmente | Já realizado |
| `ujust bbrew` | Conforme seleção | Homebrew/Flatpak | Depende | Não automático |
| `ujust jetbrains-toolbox` | Aplicativo | Home do usuário | Não | Só se usar JetBrains |
| `ujust install-opentabletdriver` | Driver | Entrada do usuário | Talvez | Só com tablet |
| `ujust setup-sunshine` | Serviço | Rede/serviço | Talvez | Só para streaming |
| `ujust cncf` | Conforme seleção | Homebrew | Depende | Só para cloud-native |
| `ujust logs-*` | Não | Não | Não | Diagnóstico |
| `ujust device-info` | Não | Envia dados | Não | Só para suporte |
| `ujust bios` | Não | Reinicia | Sim | Manual |
| `ujust bios-info` | Não | Não | Não | Consulta |
| `ujust benchmark` | Não | Carga temporária | Não | Diagnóstico |
| `ujust check-idle-power-draw` | Não | Medição | Não | Diagnóstico |
| `ujust check-local-overrides` | Não | Não | Não | Diagnóstico |
| `ujust toggle-user-motd` | Não | Configuração do banner | Não | Opcional |
| `ujust toggle-updates` | Não | Atualizações automáticas | Talvez | Decidir conscientemente |
| `ujust toggle-tailscale` | Integração | Rede | Talvez | Só se usar |
| `ujust toggle-iwd` | Não | Rede Wi-Fi | Talvez | Não alterar funcionando |
| `ujust toggle-tpm2` | Não | Criptografia | Pode | Não padrão |
| `ujust enroll-secure-boot-key` | Chave | Secure Boot | Pode | Só NVIDIA/Secure Boot |
| `ujust configure-boot-to-windows` | Não | Boot | Pode | Só dual boot |
| `ujust rebase-helper` | Imagem | Base/stream | Sim | Manutenção avançada |
| `ujust clean-system` | Remove recursos | Dados/depósitos | Não | Só após auditoria |
| `ujust powerwash` | Restaura | Dados/configuração | Sim | Nunca no fluxo normal |

A coluna “reiniciar” é dependente da versão e do estado do sistema; a mensagem exibida pela receita prevalece.

[Voltar ao índice](#indice)

<a id="validacao"></a>
## 11. Validação final

### Depois de mudanças no DX

```bash
rpm-ostree status
id -nG
podman --version
podman ps
```

### Depois de atualizações

```bash
rpm-ostree status
flatpak update --app --system
brew list --versions
```

Não use `flatpak update` como obrigação imediata se `ujust update` acabou de concluir; a consulta serve para verificar estado quando necessário.

### Depois de mudanças de imagem/rebase

```bash
rpm-ostree status
bootctl status 2>/dev/null || true
systemctl --failed
```

Se o boot ou drivers falharem, pare de aplicar comandos e preserve informações de diagnóstico.

### Depois de alterações de rede

```bash
nmcli general status
nmcli device status
```

### Depois de alterações no shell

```bash
command -v zsh
zsh -n "$HOME/.zshenv" 2>/dev/null || true
zsh -n "$HOME/.config/zsh/.zshrc" 2>/dev/null || true
command -v starship
```

### Relatório local das receitas

```bash
mkdir -p "$HOME/aurora-pos-instalacao/logs"
stamp="$(date +%Y%m%d-%H%M%S)"
{
  date
  rpm-ostree status
  ujust --list 2>/dev/null || ujust --choose
  brew list --formula
  brew list --cask
  flatpak list --app --system
  flatpak list --app --user
} > "$HOME/aurora-pos-instalacao/logs/inventario-ujust-$stamp.txt" 2>&1
```

Revise o arquivo antes de compartilhar: logs e inventários podem expor nome de usuário, hardware, caminhos, remotos e serviços.

### Regras finais do projeto

- Consultar a receita antes de executá-la.
- Não usar `sudo` em scripts de usuário ou em comandos que não exigem privilégio.
- Não executar `powerwash`, `rebase-helper`, `toggle-tpm2`, `clean-system` ou Secure Boot por curiosidade.
- Não alterar Wi-Fi funcionando para “melhorar” sem um teste reversível.
- Não remover pacotes da imagem Aurora para liberar espaço; a documentação alerta que isso pode aumentar tempo de atualização e armazenamento. [web:17]
- Não confundir `Using` do Bundle com detecção universal de duplicidade.
- Registrar comandos, saídas e reinicializações no status do projeto.

Este documento complementa `01-aurora-pronto-guia-rapido-pos-instalacao.md` e `02-aurora-em-colecoes-referencia-bbrew.md`. Consulte o guia rápido para executar o roteiro; consulte este documento para entender as receitas.

Fontes: [Uso básico do Aurora](https://docs.getaurora.dev/guides/basic-usage/), [Aurora DX](https://docs.getaurora.dev/dx/aurora-dx-intro/), [Release Streams](https://docs.getaurora.dev/guides/release-streams/), [Bold Brew](https://bold-brew.com/).

[Voltar ao índice](#indice)
