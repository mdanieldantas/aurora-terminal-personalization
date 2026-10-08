# Guia: Google Drive no Aurora Linux com rclone

Versão revisada — 8 de outubro de 2026.

Responsável pelo projeto: Marcos Daniel Gomes Dantas.

**Validado**: a pasta GoogleDrive abriu com os arquivos remotos após reiniciar o Aurora, sem executar comandos de montagem manual.

Este guia documenta a sequência funcional do projeto. Não inclui as tentativas malsucedidas do RClone Manager como passos de instalação. Verificações e cuidados acrescentados na revisão estão identificados como tais.

## Mini-sumário

- [1. Resultado e escopo](#resultado)
- [2. Ambiente e caminhos](#ambiente)
- [3. Instalar e identificar o rclone](#instalacao)
- [4. Configurar o remote Google Drive](#configuracao)
- [5. Testar o acesso remoto](#acesso)
- [6. Montar manualmente para teste](#mount-manual)
- [7. Preparar a automação](#preparacao)
- [8. Criar o serviço systemd](#servico)
- [9. Ativar sem duplicar a montagem](#ativacao)
- [10. Validar após reiniciar](#validacao)
- [11. Usar e manter a montagem](#uso)
- [12. RClone Manager — opcional](#manager)
- [13. Diagnóstico seguro](#diagnostico)
- [14. Segurança e manutenção OAuth](#seguranca)
- [15. Desativar ou reativar](#reversao)
- [16. Checklist final](#checklist)

<a id="resultado"></a>
## 1. Resultado e escopo

O objetivo foi acessar o Google Drive como uma pasta virtual no Aurora, com arquivos sob demanda, de forma semelhante à unidade usada pelo Drive para Desktop no Windows.

A solução concluída tem cinco componentes:

1. rclone do sistema em `/usr/bin/rclone`;
2. remote autenticado chamado `gdrive:`;
3. ponto de montagem `~/GoogleDrive`;
4. cache VFS para leitura e escrita;
5. serviço systemd do usuário para iniciar a montagem automaticamente.

O rclone usa FUSE para apresentar o armazenamento remoto como sistema de arquivos. Essa montagem não é o cliente oficial do Google, não reproduz todos os seus recursos e não equivale a um backup ou sincronização offline completa. [web:69]

O funcionamento do serviço foi confirmado após reiniciar. O Manager é opcional: sua integração com esse mesmo mount não foi concluída nem validada.

### Antes de repetir o guia nesta máquina

Se o serviço já está funcionando, não refaça o mount manual nem configure uma segunda montagem no mesmo local. Use os comandos de manutenção da seção 11.

<a id="ambiente"></a>
## 2. Ambiente e caminhos

### Valores observados no projeto

| Item | Valor |
|---|---|
| Distribuição | Aurora Linux |
| Base reportada pelo rclone | Fedora 44, x86_64 |
| Usuário local | `dan` |
| Home observada | `/var/home/dan` |
| rclone efetivamente utilizado | `/usr/bin/rclone` |
| Versão desse binário | `1.74.3` |
| Versão também instalada via Homebrew | `1.75.1` |
| Remote | `gdrive:` |
| Ponto de montagem | `/var/home/dan/GoogleDrive` |
| Serviço | `rclone-gdrive.service` |

As versões registram a sessão; não são versões obrigatórias para repetir o procedimento.

### Caminhos utilizados

| Finalidade | Caminho |
|---|---|
| Configuração e credenciais | `~/.config/rclone/rclone.conf` |
| Pasta de acesso ao Drive | `~/GoogleDrive` |
| Cache | `~/.cache/rclone` |
| Log | `~/.local/state/rclone/gdrive.log` |
| Unidade systemd | `~/.config/systemd/user/rclone-gdrive.service` |
| Cópia instalada pelo Homebrew | `/home/linuxbrew/.linuxbrew/bin/rclone` |

No terminal, `~` representa sua home. Na unidade systemd, usamos `%h`, que é expandido para a home pelo systemd. Não é necessário escrever `dan` dentro do arquivo de serviço.

<a id="instalacao"></a>
## 3. Instalar e identificar o rclone

O Aurora recomenda Flatpak para aplicativos gráficos e Homebrew para ferramentas de terminal. Neste projeto não usamos `dnf`, `rpm -i` nem layering de RPMs. [web:34]

### 3.1 Verificar o Homebrew

```bash
brew --version
```

O Homebrew já estava instalado quando começamos. Sua instalação não fez parte desta sessão. Se o comando não existir em outra máquina, configure-o seguindo a documentação do Aurora antes de continuar.

### 3.2 Instalação executada

```bash
brew install rclone
```

O Homebrew instalou a versão `1.75.1`, mas avisou que outro `rclone`, em `/usr/bin`, tinha prioridade no `PATH`.

### 3.3 Identificar qual binário será usado

```bash
which rclone
rclone --version
```

Resultado registrado:

```text
/usr/bin/rclone
rclone v1.74.3
```

Decisão adotada: usar o binário `/usr/bin/rclone`, que já funcionava no Aurora. A cópia Homebrew ficou instalada, mas não é a usada pelo serviço.

Para uma instalação futura, confira primeiro se já existe um rclone funcional. Não é obrigatório instalar a segunda cópia se o host já atende ao objetivo.

### 3.4 Sobre os avisos da instalação

- O aviso de Landlock não impediu a instalação observada. Não alteramos proteções do sistema.
- O aviso sobre ausência do subcomando `mount` no Homebrew no macOS não se aplica ao Aurora Linux.
- Ocultar o aviso de shadowing com `HOMEBREW_NO_PATH_SHADOW_CHECK=1` não muda a prioridade dos executáveis.

Não mudamos o `PATH` e não desinstalamos nenhuma das duas cópias.

<a id="configuracao"></a>
## 4. Configurar o remote Google Drive

### 4.1 Abrir o assistente

```bash
rclone config
```

### 4.2 Respostas efetivamente usadas

| Etapa | Resposta |
|---|---|
| Criar remote | `n` |
| Nome | `gdrive` |
| Tipo de armazenamento | Google Drive: `24` na lista da sessão |
| `client_id` | Enter, deixando vazio |
| `client_secret` | Enter, deixando vazio |
| `scope` | `1`, acesso completo (`drive`) |
| `service_account_file` | Enter, deixando vazio |
| Edit advanced config? | `n` |
| Usar navegador para autenticar? | `y` |
| Shared Drive / Team Drive? | `n` |
| Keep this "gdrive" remote? | `y` |
| Sair do menu | `q` |

O número de Google Drive pode variar entre versões. Identifique o nome ou digite `drive`, em vez de assumir que sempre será `24`. Google Cloud Storage é outro serviço.

O escopo `drive` autoriza leitura, escrita e exclusão, exceto na pasta de dados da aplicação. `drive.readonly` é a alternativa somente de leitura, mas não foi o modo utilizado. Conta de serviço e Shared Drive são cenários distintos do login pessoal escolhido. [web:32]

### 4.3 Autenticação pelo navegador

Após responder `y`, o navegador abriu para login e autorização da conta Google. O terminal retornou:

```text
Got code
```

A autenticação automática utiliza um servidor local temporário em `127.0.0.1`. Não publique essa porta na internet nem crie redirecionamento no roteador. [web:32]

No resumo final, não copie nem compartilhe o campo `token`. Para salvar, confirme `y` e depois saia com `q`.

### 4.4 Ressalva importante para novas instalações

Deixar `client_id` e `client_secret` vazios funcionou na sessão e esse é o registro fiel do que fizemos. Entretanto, a documentação atual informa que o client ID compartilhado está sendo retirado durante 2026 e recomenda fortemente criar um próprio. [web:32]

Portanto:

- para documentar esta instalação: os campos ficaram vazios;
- para uma instalação nova ou manutenção duradoura: use credenciais OAuth próprias conforme “Making your own client_id” na documentação oficial do rclone;
- a criação e migração para credenciais próprias não foi executada neste projeto e não deve ser marcada como concluída.

As perguntas do assistente de versões mais novas também podem ser diferentes. Não force respostas antigas quando houver um aviso novo de OAuth.

<a id="acesso"></a>
## 5. Testar o acesso remoto

### 5.1 Confirmar o remote local

```bash
rclone listremotes
```

Resultado:

```text
gdrive:
```

Esse comando confirma o cadastro local, mas não testa autenticação na nuvem.

### 5.2 Teste de acesso realizado

```bash
rclone ls gdrive:
```

O comando listou arquivos do Drive, inclusive em subpastas. `ls` é recursivo; não se limita à raiz. A listagem real foi a confirmação de que o login estava funcionando. [web:32]

### 5.3 Verificações adicionais para repetir o procedimento

Estes comandos são verificações acrescentadas ao guia; não foram todos executados na sessão:

```bash
rclone config file
rclone lsf gdrive: --max-depth 1
```

- `config file`: mostra onde está a configuração, sem exibir o token.
- `lsf --max-depth 1`: oferece uma listagem curta do primeiro nível.

O serviço abaixo espera `~/.config/rclone/rclone.conf`. Se `config file` apontar para outro lugar, adapte `--config` antes de ativar a unidade.

<a id="mount-manual"></a>
## 6. Montar manualmente para teste

### 6.1 Criar a pasta

```bash
mkdir -p ~/GoogleDrive
```

Antes da primeira montagem, use um diretório vazio e existente. Não utilize uma pasta com documentos locais nem acrescente `--allow-non-empty` para ignorar o problema. Essa é uma condição do mount documentada pelo rclone. [web:69]

Verificações adicionais, antes de montar:

```bash
mountpoint ~/GoogleDrive
ls -A ~/GoogleDrive
```

Se já for ponto de montagem, não execute outro mount. Se não estiver montada, mas contiver arquivos locais, pare e escolha uma pasta vazia.

### 6.2 Comando manual que funcionou

```bash
rclone mount gdrive: ~/GoogleDrive \
  --vfs-cache-mode full \
  --dir-cache-time 1000h \
  --poll-interval 15s \
  --daemon
```

`--daemon` executa em segundo plano. Não cria uma inicialização automática para os próximos logins. [web:69]

### 6.3 Conferir a montagem

```bash
ls ~/GoogleDrive
mountpoint ~/GoogleDrive
```

A listagem mostrou o conteúdo remoto. A verificação retornou:

```text
/var/home/dan/GoogleDrive is a mountpoint
```

No Dolphin, abra sua pasta pessoal e entre em GoogleDrive.

Essa etapa foi temporária para validar a montagem. Depois ela foi substituída pelo serviço, não mantida em paralelo.

<a id="preparacao"></a>
## 7. Preparar a automação

### 7.1 Diretórios criados

```bash
mkdir -p ~/.config/systemd/user
mkdir -p ~/.cache/rclone
mkdir -p ~/.local/state/rclone
```

Verificação realizada:

```bash
ls -ld ~/.config/systemd/user ~/.cache/rclone ~/.local/state/rclone
```

As três pastas apareceram corretamente.

### 7.2 Conferências adicionais antes de repetir em outra máquina

```bash
/usr/bin/rclone version
command -v fusermount3
rclone config file
```

O serviço usa `/usr/bin/rclone`, `/usr/bin/fusermount3` e o arquivo de configuração na home. Confirme esses caminhos; não invente caminhos caso os comandos falhem.

Se o helper estiver em outro local, adapte `ExecStop`. Se o rclone não existir em `/usr/bin`, será necessário adaptar e testar `ExecStart` antes de prosseguir.

<a id="servico"></a>
## 8. Criar o serviço systemd

### 8.1 Criar o arquivo usado no projeto

O bloco abaixo grava a unidade local. Se o arquivo já existir, ele será sobrescrito. Em uma repetição do procedimento, revise ou faça uma cópia antes; não execute por necessidade se o serviço já está funcionando.

```bash
cat > ~/.config/systemd/user/rclone-gdrive.service <<'EOF'
[Unit]
Description=Mount Google Drive with rclone
Documentation=https://rclone.org/commands/rclone_mount/
After=graphical-session-pre.target
Wants=graphical-session-pre.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount gdrive: %h/GoogleDrive \
  --config=%h/.config/rclone/rclone.conf \
  --cache-dir=%h/.cache/rclone \
  --vfs-cache-mode=full \
  --vfs-cache-max-size=10G \
  --vfs-cache-max-age=24h \
  --dir-cache-time=1000h \
  --poll-interval=15s \
  --log-file=%h/.local/state/rclone/gdrive.log \
  --log-level=INFO
ExecStop=/usr/bin/fusermount3 -uz %h/GoogleDrive
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
```

Esse arquivo é idêntico à unidade confirmada no terminal e validada após reboot.

### 8.2 Conferir o conteúdo

```bash
cat ~/.config/systemd/user/rclone-gdrive.service
```

Não há tokens nesse arquivo: ele aponta para a configuração separada do rclone.

### 8.3 Explicação dos parâmetros

| Parâmetro | Função |
|---|---|
| `Type=notify` | O rclone avisa quando a montagem está pronta. |
| `ExecStart=/usr/bin/rclone` | Fixa a cópia do host que foi validada. |
| `%h` | Representa a home do usuário na unidade. |
| `--config` | Define explicitamente o arquivo do remote. |
| `--cache-dir` | Define o diretório de cache. |
| `--vfs-cache-mode=full` | Cacheia leituras e escritas em disco para compatibilidade. |
| `--vfs-cache-max-size=10G` | Meta de tamanho do cache; não é um teto rígido. |
| `--vfs-cache-max-age=24h` | Prazo desde o último acesso para expiração de itens elegíveis. |
| `--dir-cache-time=1000h` | Cache de metadados de diretórios, não retenção offline de arquivos. |
| `--poll-interval=15s` | Consulta mudanças remotas em backends com polling. |
| `--log-file` | Arquivo com mensagens do rclone. |
| `Restart=on-failure` | Solicita reinício após falha do processo. |
| `RestartSec=10` | Espera dez segundos entre tentativas. |
| `WantedBy=default.target` | Habilita no gerenciador systemd do usuário. |

A documentação confirma `Type=notify` e o funcionamento do cache. A limpeza é periódica e arquivos abertos não podem ser removidos, por isso o cache pode ultrapassar `10G`. `24h` conta desde o último acesso, não desde a criação. [web:69]

Não use `--daemon` dentro deste serviço: o processo deve permanecer sob supervisão direta do systemd.

### 8.4 Limites da automação

- É uma unidade do usuário, sem `sudo`.
- Não configuramos `loginctl enable-linger` nem serviço global de sistema.
- O resultado foi validado ao entrar na sessão após reiniciar, não antes do login.
- `After=graphical-session-pre.target` não garante que haverá internet naquele momento.
- Reinícios automáticos podem encontrar limites de tentativas do systemd; não são garantia de recuperação infinita.
- `ExecStop` usa `-z`, desmontagem lazy. Isso não garante conclusão dos uploads: feche arquivos e aguarde os envios antes de parar.
- Não configuramos rotação automática do arquivo de log.

<a id="ativacao"></a>
## 9. Ativar sem duplicar a montagem

### 9.1 Preparar a troca

Feche arquivos abertos em GoogleDrive, aguarde os uploads e encerre cópias. O mount manual ainda está ativo nesta etapa.

Não configure o Manager para montar no mesmo local.

### 9.2 Desmontar a montagem manual

```bash
fusermount3 -u ~/GoogleDrive
```

Na sessão esse comando funcionou sem erro.

Para repetir com mais segurança, confira em seguida:

```bash
mountpoint ~/GoogleDrive
```

O esperado nesse intervalo é não ser ponto de montagem. Se a desmontagem falhar ou continuar montado, não avance: feche aplicativos usando a pasta e investigue.

Desmontar retira a visualização da nuvem, não apaga os documentos remotos. [web:69]

### 9.3 Carregar e habilitar a unidade

```bash
systemctl --user daemon-reload
systemctl --user enable --now rclone-gdrive.service
```

### 9.4 Verificar

```bash
sleep 3
systemctl --user status rclone-gdrive.service --no-pager
```

Resultado registrado:

```text
Loaded: loaded (.../rclone-gdrive.service; enabled; preset: disabled)
Active: active (running)
Main PID: ... (rclone)
```

`enabled` indica que foi habilitado. `preset: disabled` é a política padrão, não uma falha da habilitação feita pelo usuário.

O status também mostrou aproximadamente `4.806Mi` de cache e `to upload 0, uploading 0` naquele instante. Isso era uma fotografia daquele momento, não uma garantia permanente de ausência de uploads.

<a id="validacao"></a>
## 10. Validar após reiniciar

Depois de salvar seu trabalho e aguardar os uploads:

1. Reinicie pelo menu do Aurora.
2. Entre na sessão.
3. Abra o Dolphin.
4. Abra a pasta GoogleDrive na sua home.
5. Confirme que os arquivos aparecem sem montar manualmente.

O usuário realizou esse teste e confirmou que funcionou.

Verificações adicionais opcionais:

```bash
systemctl --user is-enabled rclone-gdrive.service
systemctl --user is-active rclone-gdrive.service
mountpoint ~/GoogleDrive
```

Resultados esperados:

```text
enabled
active
/var/home/dan/GoogleDrive is a mountpoint
```

Nesta máquina, a configuração principal está concluída. Não é necessário abrir o Manager nem o terminal para iniciar o Drive no uso diário normal.

<a id="uso"></a>
## 11. Usar e manter a montagem

### 11.1 Acesso no Dolphin

Abra `~/GoogleDrive`. Na máquina deste projeto, o caminho observado é `/var/home/dan/GoogleDrive`.

Você pode adicioná-la aos Locais do Dolphin. A pasta permite acessar arquivos remotos, conforme as permissões do Google Drive.

Criar, renomear, mover ou excluir arquivos nela afeta o armazenamento remoto. Não a trate como uma pasta descartável de teste. No backend Google Drive, exclusões usam a lixeira por padrão, mas isso não substitui um backup. [web:32]

### 11.2 Cuidados com leitura, escrita e uploads

No modo `full`, o rclone mantém dados de leitura/escrita em cache. Um arquivo salvo localmente ainda pode estar aguardando upload. O envio acontece depois de fechado e após o intervalo de write-back; sem ajuste explícito, a documentação indica cinco segundos. [web:69]

Para acompanhar:

```bash
tail -f ~/.local/state/rclone/gdrive.log
```

Ctrl+C encerra apenas o acompanhamento, não o serviço.

Para arquivos importantes, além dos logs, confirme a presença/versão no site do Google Drive. Não suspenda ou desligue durante envios.

Não apague o cache quando houver uploads pendentes. Se o rclone terminar antes do envio, a documentação prevê retomada ao iniciar com os mesmos parâmetros/cache; preserve esse cache e investigue antes de limpar. [web:69]

### 11.3 Não criar instâncias concorrentes

Não execute outro `rclone mount` sobre `~/GoogleDrive` enquanto o serviço estiver ativo.

Também não use o mesmo cache VFS em duas instâncias com remotes iguais ou sobrepostos: isso pode causar corrupção. Testes de uma GUI devem ser sequenciais e usar cache separado quando necessário. [web:69]

### 11.4 Offline, backup e projetos grandes

- O cache não garante que toda a pasta ficará disponível offline.
- Arquivos ainda não cacheados dependem de internet.
- A montagem não é uma cópia de backup independente.
- Para áudio, vídeo, VMs e bancos de dados, prefira trabalhar localmente e transferir versões fechadas/concluídas. A nuvem não oferece o mesmo comportamento de um disco local. [web:69]

### 11.5 Google Docs, Sheets e Slides

A listagem mostrou alguns arquivos com tamanho `-1` e extensões Office. Google Docs nativos podem ser apresentados como exportações DOCX/XLSX/PPTX, não como arquivos convencionais originalmente armazenados nesses formatos.

Exportar e importar documentos Google são operações específicas do backend. Não presuma que editar uma exportação no mount atualizará automaticamente o documento nativo como no navegador. Para colaboração e documentos Google nativos, use o navegador até compreender/configurar esse comportamento. [web:32]

### 11.6 Atenção aos atalhos de pastas

O Drive pode conter atalhos para outras pastas. A documentação alerta que excluir conteúdo de um atalho de pasta pelo mount pode excluir o conteúdo da pasta de destino. Não confunda remover um atalho com apagar a pasta acessível através dele. [web:32]

### 11.7 Mount não é sync

Esta solução usa somente mount para acesso remoto. Não há `sync`, `copy` agendado ou `bisync` configurado.

`rclone sync` espelha a origem no destino em uma direção e pode excluir arquivos extras do destino. Alternar dois `sync` em sentidos opostos não equivale a sincronização bidirecional segura. Não utilize esses comandos para “completar” o setup atual. [web:84]

### 11.8 Comandos úteis

| Ação | Comando |
|---|---|
| Estado detalhado | `systemctl --user status rclone-gdrive.service --no-pager` |
| Habilitação | `systemctl --user is-enabled rclone-gdrive.service` |
| Montagem | `mountpoint ~/GoogleDrive` |
| Iniciar | `systemctl --user start rclone-gdrive.service` |
| Parar | `systemctl --user stop rclone-gdrive.service` |
| Reiniciar | `systemctl --user restart rclone-gdrive.service` |
| Journal recente | `journalctl --user -u rclone-gdrive.service -n 80 --no-pager` |
| Log recente do rclone | `tail -n 80 ~/.local/state/rclone/gdrive.log` |
| Log ao vivo do rclone | `tail -f ~/.local/state/rclone/gdrive.log` |
| Cache ocupado | `du -sh ~/.cache/rclone` |
| Espaço livre local | `df -h "$HOME"` |
| Quota remota | `rclone about gdrive:` |

Como `--log-file` foi definido, mensagens detalhadas do rclone ficam principalmente no arquivo de log. O journal ajuda a acompanhar o ciclo do serviço.

Antes de parar ou reiniciar, feche arquivos e aguarde uploads.

Após uma edição planejada da unidade:

```bash
systemctl --user daemon-reload
systemctl --user restart rclone-gdrive.service
systemctl --user status rclone-gdrive.service --no-pager
```

Atualizar a cópia Homebrew não atualiza o binário `/usr/bin/rclone` usado pelo serviço. Não mude `ExecStart` sem um teste planejado.

<a id="manager"></a>
## 12. RClone Manager — opcional

### 12.1 O que foi confirmado

- O aplicativo foi instalado pelo Bazaar como Flatpak.
- Seu identificador é `io.github.zarestia_dev.rclone-manager`.
- O assistente avançou até a escolha de configuração do rclone.
- Foi orientada a seleção de `rclone.conf` na etapa específica de configuração.
- Foi escolhido Painel clássico.
- O painel principal abriu e mostrou um remote Drive.

A descrição do painel citava `grive`, mas o terminal confirmou apenas `gdrive:`. Não houve confirmação suficiente do caminho/configuração efetivos da GUI. Portanto, não afirmamos que ela gerencia o mesmo remote ou o mesmo mount do serviço.

### 12.2 Instalação por terminal, se necessário

Não repita se já instalou pelo Bazaar:

```bash
flatpak install flathub io.github.zarestia_dev.rclone-manager
```

Abrir:

```bash
flatpak run io.github.zarestia_dev.rclone-manager
```

Flatpak é o método recomendado pelo Aurora para aplicativos gráficos. [web:34]

### 12.3 Selecionar configuração não é importar backup

Para fornecer a configuração do rclone, use a tela “Selecione a Configuração do Rclone”, opção Personalizado, e escolha:

```text
/var/home/dan/.config/rclone/rclone.conf
```

Isso é diferente do botão Importar nas boas-vindas, que nessa sessão solicitava um backup `.rcman` do Manager. Não renomeie `rclone.conf` nem o forneça como backup `.rcman`.

### 12.4 O que este guia não promete

Não há aqui um procedimento validado para selecionar/instalar o binário pelo assistente Flatpak: os caminhos tentados deram erro e o caminho final aceito não foi registrado.

Por isso, as tentativas de binário e permissões foram removidas do passo a passo. Não é necessário reproduzi-las para usar a montagem já concluída.

A documentação do Manager contém orientações específicas de permissões e acesso a binários do host, mas elas não são etapas obrigatórias do serviço systemd deste guia. Não libere home/D-Bus nem altere FUSE sem um problema concreto e diagnóstico. [web:60]

Não configure o Manager para montar em `~/GoogleDrive` junto com o serviço. Fechar a janela pode deixar o app na bandeja; encerre-o completamente antes de testes que precisem garantir que ele não está executando tarefas. [web:60]

O Rclone UI não foi instalado nem testado neste projeto.

<a id="diagnostico"></a>
## 13. Diagnóstico seguro

Os comandos desta seção são recursos de manutenção, não passos que precisaram ser executados para concluir o projeto.

### 13.1 Se não iniciar

```bash
systemctl --user status rclone-gdrive.service --no-pager
journalctl --user -u rclone-gdrive.service -n 80 --no-pager
tail -n 80 ~/.local/state/rclone/gdrive.log
/usr/bin/rclone version
rclone config file
rclone listremotes
```

Confira conexão, caminhos, existência de `gdrive` e erro exato. Não apague cache nem instale outra cópia para tentar resolver sem diagnóstico.

Se o systemd tiver bloqueado novas tentativas após muitas falhas, primeiro corrija a causa; então:

```bash
systemctl --user reset-failed rclone-gdrive.service
systemctl --user start rclone-gdrive.service
```

### 13.2 Se a pasta estiver vazia

```bash
mountpoint ~/GoogleDrive
rclone lsf gdrive: --max-depth 1
```

Sem mount, você pode estar vendo apenas a pasta local vazia; isso não prova exclusão dos arquivos na nuvem.

Se a listagem remota funciona, investigue o serviço. Se também falha, investigue rede e autenticação.

### 13.3 Se o ponto estiver ocupado

```bash
mountpoint ~/GoogleDrive
systemctl --user status rclone-gdrive.service --no-pager
```

Feche arquivos e janelas usando a pasta. Se pertence ao serviço, controle pelo systemd. Se é montagem manual, após aguardar uploads use `fusermount3 -u ~/GoogleDrive`.

Não comece com `kill -9`, `--allow-non-empty` ou remoção recursiva.

### 13.4 Se houver erro OAuth

Identifique primeiro se o erro é de token revogado, client ID ou conectividade. Reconectar não cria um client ID próprio.

Se for necessário reautenticar, faça em manutenção planejada, com arquivos fechados e uploads concluídos:

```bash
systemctl --user stop rclone-gdrive.service
rclone config reconnect gdrive:
```

Conclua a autorização no navegador. Depois teste o remote:

```bash
rclone lsf gdrive: --max-depth 1
```

Somente se funcionar, inicie novamente:

```bash
systemctl --user start rclone-gdrive.service
```

Se a causa for retirada do client ID compartilhado, siga a migração da documentação oficial, não apenas reconnect. [web:32]

### 13.5 Se o cache crescer

```bash
du -sh ~/.cache/rclone
df -h "$HOME"
```

`10G` pode ser excedido, especialmente com arquivos abertos/grandes. Não apague conteúdo do cache que ainda precisa ser enviado. [web:69]

<a id="seguranca"></a>
## 14. Segurança e manutenção OAuth

### 14.1 Arquivo sensível

Não publique `rclone.conf`, tokens, códigos OAuth nem capturas do resumo com credenciais. O guia não contém esses valores.

Medida adicional de proteção local, não registrada como executada no projeto:

```bash
chmod 600 ~/.config/rclone/rclone.conf
```

Isso restringe permissões tradicionais ao proprietário, mas não criptografa o arquivo nem protege contra acesso à sessão do próprio usuário.

Não habilite criptografia da configuração sem planejar como o serviço obterá a senha; um prompt interativo pode impedir a automação.

### 14.2 Credencial exibida durante a sessão

Um access token foi colado durante a conversa. Não o reproduzimos no documento. Por prudência, trate-o como potencialmente exposto: se houve compartilhamento público, acesso de terceiros ou dúvida sobre quem teve acesso, revogue a autorização do rclone na Conta Google e reautentique em manutenção planejada.

Não afirme que um refresh token foi exposto sem conferir; também não assuma que a expiração do access token protege credenciais adicionais eventualmente compartilhadas.

### 14.3 Client ID próprio: pendência real

A documentação atual informa que o client ID compartilhado será retirado durante 2026. A autenticação que fizemos funcionou, mas não é uma garantia de continuidade. Planeje credenciais OAuth próprias seguindo a seção oficial “Making your own client_id”. [web:32]

Preserve o nome `gdrive` na migração para manter o serviço apontando para o mesmo remote. Faça mudanças com uploads concluídos, preserve backup protegido da configuração e valide uma listagem antes de retomar o serviço.

A criação de um aplicativo OAuth não foi realizada neste projeto. Não é uma etapa retroativamente concluída nem exige alterar agora o serviço que já funciona sem planejar a migração.

<a id="reversao"></a>
## 15. Desativar ou reativar

Depois de fechar arquivos e aguardar uploads:

### Parar temporariamente

```bash
systemctl --user stop rclone-gdrive.service
```

Para voltar:

```bash
systemctl --user start rclone-gdrive.service
```

### Desativar a inicialização automática e parar

```bash
systemctl --user disable --now rclone-gdrive.service
```

Isso preserva configuração, cache e arquivos remotos.

Para reativar:

```bash
systemctl --user enable --now rclone-gdrive.service
```

Se não quiser a GUI, remova apenas o Manager pelo Bazaar, após garantir que ele não executa tarefas. O serviço não depende dela.

Nunca execute remoção recursiva sobre `~/GoogleDrive` enquanto estiver montada: você pode atingir os arquivos remotos. Desabilitar o serviço é a reversão segura para esta configuração; não é necessário apagar diretórios ou desinstalar rclone.

<a id="checklist"></a>
## 16. Checklist final

### Concluído e confirmado na sessão

- [x] Homebrew já disponível.
- [x] `brew install rclone` executado com sucesso.
- [x] Prioridade de `/usr/bin/rclone` identificada.
- [x] Escolhida a cópia do host para configuração e serviço.
- [x] Remote `gdrive:` criado e autenticado.
- [x] Listagem real do Drive funcionando.
- [x] Montagem manual funcionando em `~/GoogleDrive`.
- [x] Diretórios de unidade, cache e logs criados.
- [x] Unidade systemd criada e conferida.
- [x] Montagem manual desmontada.
- [x] Serviço habilitado e iniciado.
- [x] Estado `active (running)` confirmado.
- [x] Reinicialização realizada.
- [x] Acesso pelo Dolphin confirmado após reiniciar.

### Opcionais ou pendências — não marcados como realizados

- [ ] Migrar para client ID próprio conforme a documentação atual.
- [ ] Avaliar/revogar credencial potencialmente exposta, conforme o risco.
- [ ] Confirmar caminhos e remote efetivos do Manager antes de usá-lo para montagem.
- [ ] Planejar rotação do arquivo de log, se necessário.

A configuração principal validada é rclone do host + `gdrive:` + `~/GoogleDrive` + systemd do usuário. Ela inicia automaticamente na sessão e não depende da GUI.
