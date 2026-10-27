**Guia consolidado — Google Drive no Aurora com rclone**  
Edição corrigida • 27 de outubro de 2026  
Documento operacional e histórico de manutenção. Sem tokens ou chaves secretas.  
**Mini-sumário**  
- [1. Estado atual e limites da validação](#anchor-1 "#anchor-1")  
- [2. Ambiente, componentes e caminhos](#anchor-2 "#anchor-2")  
- [3. Uso diário e verificação rápida](#anchor-3 "#anchor-3")  
- [4. Incidente: invalid_grant e correção do diagnóstico](#anchor-4 "#anchor-4")  
- [5. Google Cloud: projeto e credenciais existentes](#anchor-5 "#anchor-5")  
- [6. GitHub Pages: site informativo e privacidade](#anchor-6 "#anchor-6")  
- [7. Branding: preenchimento que liberou a publicação](#anchor-7 "#anchor-7")  
- [8. Produção, privacidade, custos e limites](#anchor-8 "#anchor-8")  
- [9. Renovação da autorização: sequência validada](#anchor-9 "#anchor-9")  
- [10. Reconstrução em outra instalação: verificar antes](#anchor-10 "#anchor-10")  
- [11. Unidade systemd preservada do guia validado](#anchor-11 "#anchor-11")  
- [12. Cache, uploads e cuidados com dados](#anchor-12 "#anchor-12")  
- [13. Diagnóstico seguro sem reinstalar](#anchor-13 "#anchor-13")  
- [14. Comandos de manutenção e reversão](#anchor-14 "#anchor-14")  
- [15. Segurança, backup de configuração e GUI](#anchor-15 "#anchor-15")  
- [16. Checklist final e pendências reais](#anchor-16 "#anchor-16")  
- [17. Base documental e histórico desta edição](#anchor-17 "#anchor-17")  
**1. Estado atual e limites da validação**  
Atualizado em 27/10/2026, após confirmação às 09:14 (-03).  
   
 Responsável: Marcos Daniel Gomes Dantas.  
Resultado confirmado na conversa:  
- Aplicativo OAuth `rclone gdrive Aurora Dan` em produção.  
- Credenciais próprias já estavam configuradas antes desta manutenção; não foram criadas agora.  
- Autorização renovada após a publicação.  
- Listagem remota funcionando com o binário e a configuração usados pelo serviço.  
- Serviço ativo e pasta montada.  
- Serviço habilitado, conforme diagnóstico de 26/10.  
Saída final fornecida pelo usuário:  
```  
active  
 /var/home/dan/GoogleDrive is a mountpoint  
   
```  
O guia anterior registrava um teste bem-sucedido após reiniciar. Nesta manutenção, não foi confirmado um novo reboot após a mudança OAuth. Esse teste permanece recomendado, não marcado como realizado.  
Este documento consolida o guia antigo e a manutenção de 26–27/10. Não modifica automaticamente os artefatos anteriores. A referência operacional passa a ser esta edição.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**2. Ambiente, componentes e caminhos**  
- Sistema: Aurora Linux; base Fedora registrada no histórico, não novamente auditada nesta sessão.  
- Usuário: `dan`; home: `/var/home/dan`.  
- Binário efetivamente usado: `/usr/bin/rclone`.  
- Versão observada no diagnóstico de 26/10: `1.75.2`.  
- Helper FUSE observado: `/usr/bin/fusermount3`.  
- Remote: `gdrive:`.  
- Pasta: `~/GoogleDrive`.  
- Unidade: `rclone-gdrive.service`.  
- Configuração: `~/.config/rclone/rclone.conf`.  
- Cache: `~/.cache/rclone`.  
- Log: `~/.local/state/rclone/gdrive.log`.  
- Arquivo da unidade: `~/.config/systemd/user/rclone-gdrive.service`.  
Há registro histórico de outra cópia via Homebrew. Sua versão atual não foi verificada. Atualizar essa cópia não atualiza necessariamente `/usr/bin/rclone`.  
O remote, a pasta e o nome do aplicativo OAuth são entidades diferentes. Mudar o nome de exibição no Google não exige renomear `gdrive:` ou o serviço.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**3. Uso diário e verificação rápida**  
Abra `~/GoogleDrive` no Dolphin. O serviço do usuário foi habilitado para iniciar na sessão, sem precisar abrir uma GUI do rclone.  
Verificação:  
```  
systemctl --user is-enabled rclone-gdrive.service  
 systemctl --user is-active rclone-gdrive.service  
 mountpoint "$HOME/GoogleDrive"  
   
```  
Esperado: `enabled`, `active` e indicação de que a pasta é um mountpoint.  
Se o serviço estiver parado, sem outra montagem manual concorrente:  
```  
systemctl --user start rclone-gdrive.service  
   
```  
Não recrie o remote nem repita a instalação numa máquina já funcional.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**4. Incidente: invalid_grant e correção do diagnóstico**  
Em 26/10 o serviço falhava com código 1 e reiniciava repetidamente. O log identificou:  
```  
couldn't fetch token: invalid_grant: maybe token expired?  
   
```  
Isso demonstra falha na renovação da autorização, mas não identifica sozinho todos os possíveis motivos. Não era evidência de problema no FUSE ou de falta de arquivos na nuvem.  
O diagnóstico local mostrou acesso remoto funcional depois, serviço ativo e montagem funcionando. As últimas linhas de erro mostradas eram de um horário anterior: histórico de erro não equivale a falha atual.  
O script antigo procurava `client_id` e `client_secret` no arquivo inteiro. Isso não prova que pertencem especificamente à seção `[gdrive]`, nem valida as credenciais. O teste remoto posterior usando explicitamente o mesmo binário e arquivo de configuração ofereceu evidência mais forte.  
Depois, o usuário confirmou no Google Cloud que o aplicativo estava em `Testando`. A documentação do Google explica que autorizações nesse modo expiram após sete dias e que o refresh token também expira para esse tipo de acesso ao Drive.  
Conclusão: o modo de teste era uma causa concreta de expiração periódica, compatível com a recorrência. Não é possível provar retrospectivamente que causou cada falha anterior.  
Correções em relação às orientações antigas:  
- Não presumir ausência de client ID próprio: o usuário informou que já existia.  
- Não dizer que criar novas chaves resolve tudo.  
- Não insistir em mudar o nome do app para liberar publicação.  
- No Console observado, foi necessário completar página inicial, privacidade e domínio no Branding.  
- Reconectar não é o procedimento para inserir novas credenciais; ele reautoriza o remote existente.  
- Produção remove a expiração específica de teste, não garante autorização eterna.  
Base: documentação Google de público-alvo e histórico da manutenção.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**5. Google Cloud: projeto e credenciais existentes**  
Projeto utilizado: `axial-studio-511113-v9`.  
   
 Aplicativo: `rclone gdrive Aurora Dan`.  
   
 Tipo de usuário: Externo.  
   
 Cliente OAuth: aplicativo para computador.  
   
 Estado final informado pelo usuário: Em produção.  
Branding:  
   
 [https://console.cloud.google.com/auth/branding?project=axial-studio-511113-v9](https://console.cloud.google.com/auth/branding?project=axial-studio-511113-v9 "https://console.cloud.google.com/auth/branding?project=axial-studio-511113-v9")  
Público-alvo:  
   
 [https://console.cloud.google.com/auth/audience?project=axial-studio-511113-v9](https://console.cloud.google.com/auth/audience?project=axial-studio-511113-v9 "https://console.cloud.google.com/auth/audience?project=axial-studio-511113-v9")  
Credenciais, conforme a interface: Google Auth Platform → Clientes.  
Não foi necessário criar outro projeto, outro client ID ou outra chave secreta nesta correção. O documento não reproduz valores de client ID, segredos, tokens ou códigos de autenticação.  
Para uma instalação nova, em outro contexto: ativar Google Drive API, configurar o consentimento e criar um cliente OAuth para computador conforme a documentação atual do rclone. Não reaplicar esses passos na instalação já pronta.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**6. GitHub Pages: site informativo e privacidade**  
Conta GitHub: `mdanieldantas`.  
   
 Repositório público criado: `rclone-aurora-info`.  
   
 Arquivos criados pelo usuário:  
- `index.html`: apresentação e finalidade pessoal.  
- `privacidade.html`: política de privacidade.  
Publicação configurada: Settings → Pages → Deploy from a branch → `main` → `/ (root)` → Save.  
Endereços usados:  
```  
https://mdanieldantas.github.io/rclone-aurora-info/  
 https://mdanieldantas.github.io/rclone-aurora-info/privacidade.html  
   
```  
Editor no navegador:  
```  
https://github.dev/mdanieldantas/rclone-aurora-info  
   
```  
No repositório aberto no GitHub, a tecla `.` também abre o editor web.  
O usuário confirmou a publicação do site. O conteúdo remoto dessas páginas não pôde ser validado independentemente pela ferramenta de consulta durante a sessão.  
O site é informativo: não deve conter login próprio, tokens, arquivos pessoais ou cópia do `rclone.conf`. O repositório público não torna o Drive público.  
A página inicial e a política foram originalmente redigidas com o nome `rclone Aurora Dan`. Recomenda-se alinhar seus títulos ao nome final `rclone gdrive Aurora Dan`; essa atualização editorial não foi confirmada como realizada.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**7. Branding: preenchimento que liberou a publicação**  
Valores finais orientados e seguidos de confirmação de publicação:  
- Nome: `rclone gdrive Aurora Dan`.  
- E-mail de suporte: `contatomarcosdgomes@gmail.com`.  
- Logotipo: vazio.  
- Página inicial: `https://mdanieldantas.github.io/rclone-aurora-info/`.  
- Política: `https://mdanieldantas.github.io/rclone-aurora-info/privacidade.html`.  
- Termos de serviço: vazio; não foi criada página de termos.  
- Domínio autorizado: `mdanieldantas.github.io`.  
- Contato do desenvolvedor: `contatomarcosdgomes@gmail.com`.  
Erro observado: o domínio isolado foi colocado no campo de Termos de Serviço. O Console exigiu HTTP/HTTPS e informou domínio ausente.  
Correção aplicada:  
1. Apagar o domínio do campo Termos de Serviço.  
2. Clicar em Adicionar domínio, na seção Domínios autorizados.  
3. Inserir somente `mdanieldantas.github.io`, sem protocolo e sem caminho.  
4. Salvar.  
5. Abrir Público-alvo, publicar e confirmar Em produção.  
A documentação atual do rclone recomenda preencher página inicial, política e domínio; cita GitHub Pages como opção. Não usar URLs inventadas ou sites de terceiros como se fossem próprios.  
Se uma instalação futura exigir propriedade de domínio ou verificação adicional, seguir a mensagem específica. O sucesso deste projeto não garante que a interface e as exigências serão idênticas para todos.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**8. Produção, privacidade, custos e limites**  
Publicação OAuth e compartilhamento de arquivos são coisas diferentes. Em produção, um app Externo pode ser autorizado por outras contas para os dados delas; isso não concede a essas contas acesso ao Drive de Marcos.  
Verificação formal do aplicativo é outra etapa, diferente do status de publicação. Produção não significa automaticamente verificado. Avisos ou exigências do Google devem ser avaliados conforme escopos e público do app.  
O banner de teste do Cloud com créditos não precisava ser ativado para esta mudança. Não houve relato de contratação ou cadastro de cartão para resolver o problema.  
Este guia não promete API ilimitada e gratuita para sempre. Consulte limites, condições e eventual faturamento do projeto diretamente no Google antes de contratar serviços ou aumentar muito o uso. O armazenamento contratado no Google Drive é separado do status OAuth.  
No modo de teste, a regra de sete dias aplica-se ao acesso ao Drive descrito aqui. Em produção essa regra específica deixa de ser a limitação, mas revogação, políticas de conta e outros problemas ainda podem exigir reautenticação.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**9. Renovação da autorização: sequência validada**  
Procedimento realizado em 27/10 após publicar o app. Não repetir agora sem necessidade.  
Antes: fechar documentos na montagem, encerrar cópias e aguardar uploads. A desmontagem não é garantia de conclusão de envios.  
Parar:  
```  
systemctl --user stop rclone-gdrive.service  
   
```  
Reautorizar usando o mesmo executável e configuração do serviço:  
```  
/usr/bin/rclone --config="$HOME/.config/rclone/rclone.conf" config reconnect gdrive:  
   
```  
Respostas confirmadas:  
```  
Token already configured - replace it?                 y  
 Use web browser to automatically authenticate ...?    y  
 Configure this as a Shared Drive (Team Drive)?         n  
   
```  
No navegador, selecionar a própria conta e conferir a identidade do aplicativo antes de autorizar. O log registrou `Got code`.  
Shared Drive é unidade de organização; não é sinônimo de pastas comuns compartilhadas com o usuário.  
O callback local `http://127.0.0.1:53682/` é temporário. Não abrir porta no roteador nem publicar esse endpoint. Não reproduzir URLs com estado OAuth ou códigos em documentação pública.  
Testar:  
```  
/usr/bin/rclone --config="$HOME/.config/rclone/rclone.conf" lsf gdrive: --max-depth 1  
   
```  
A listagem funcionou. Nomes privados não são reproduzidos neste guia.  
Somente após sucesso:  
```  
systemctl --user reset-failed rclone-gdrive.service  
 systemctl --user start rclone-gdrive.service  
 systemctl --user is-active rclone-gdrive.service  
 mountpoint "$HOME/GoogleDrive"  
   
```  
A saída final foi `active` e `/var/home/dan/GoogleDrive is a mountpoint`.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**10. Reconstrução em outra instalação: verificar antes**  
Esta seção é referência, não tarefa pendente para a máquina atual.  
Primeiro verificar:  
```  
command -v rclone  
 /usr/bin/rclone version  
 command -v fusermount3  
 /usr/bin/rclone config file  
   
```  
Se caminhos não existirem, adaptar ao sistema real antes de usar a unidade abaixo. Não instalar uma segunda cópia apenas por hábito. No histórico, Homebrew instalou rclone, mas o serviço continuou usando o binário do host.  
Para um remote novo, executar `/usr/bin/rclone config` apenas se esse binário existir. Selecionar:  
- Novo remote: `gdrive`.  
- Storage: `drive`, não Google Cloud Storage; números da lista variam.  
- Client ID e secret próprios.  
- Escopo: `drive` para acesso completo pretendido; `drive.readonly` se o objetivo for apenas leitura.  
- Conta de serviço: vazia neste cenário de login pessoal.  
- Autenticação pelo navegador: sim, se houver navegador local.  
- Shared Drive: não para este cenário.  
- Confirmar o remote e sair.  
Antes de automatizar, confirmar a listagem usando explicitamente o arquivo que será usado pela unidade.  
Criar diretórios apenas se necessário:  
```  
mkdir -p "$HOME/GoogleDrive" "$HOME/.config/systemd/user"  
 mkdir -p "$HOME/.cache/rclone" "$HOME/.local/state/rclone"  
   
```  
O ponto de montagem deve existir e estar vazio antes do primeiro mount. Se já for mountpoint, não iniciar uma segunda montagem. Se houver arquivos locais, não usar `--allow-non-empty` para ocultar o problema.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**11. Unidade systemd preservada do guia validado**  
Arquivo: `~/.config/systemd/user/rclone-gdrive.service`.  
   
 Conteúdo preservado do guia anterior; não houve edição integral nem nova comparação do arquivo durante esta manutenção. O ExecStart mostrado no status é compatível com os parâmetros abaixo.  
Não sobrescrever a unidade funcional por rotina. Para reconstrução, criar o arquivo com editor e revisar antes de ativar.  
```  
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
   
```  
Depois de criar ou editar deliberadamente a unidade:  
```  
systemctl --user daemon-reload  
   
```  
Somente se não houver mount manual concorrente e o remote já tiver passado no teste:  
```  
systemctl --user enable --now rclone-gdrive.service  
 systemctl --user status rclone-gdrive.service --no-pager  
   
```  
Se estiver migrando de mount manual, encerrar cópias e aguardar uploads antes de desmontá-lo com `fusermount3 -u "$HOME/GoogleDrive"`. Confirmar a desmontagem antes de iniciar o serviço.  
Não usar `--daemon` dentro desta unidade. O processo fica sob supervisão do systemd. Não usar `sudo` para esses comandos de serviço do usuário.  
Limites preservados:  
- `%h` representa a home na unidade, não a sintaxe `~` do shell.  
- `Type=notify` aguarda notificação de montagem pronta.  
- A ordem gráfica não garante internet disponível.  
- `Restart=on-failure` não resolve credenciais inválidas e pode gerar milhares de tentativas.  
- `ExecStop` usa desmontagem lazy (`-z`); não garante conclusão de uploads.  
- Não foi configurado linger nem acesso antes do login.  
- Rotação automática do log não foi configurada.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**12. Cache, uploads e cuidados com dados**  
O mount é um acesso virtual à nuvem, não um espelho offline completo nem backup independente.  
Configuração preservada:  
- `full`: cache de leituras e escritas.  
- `10G`: meta de tamanho, não teto rígido; arquivos abertos e limpeza periódica podem permitir excedentes.  
- `24h`: prazo desde o último acesso para expiração dos itens elegíveis.  
- `1000h`: cache de metadados de diretórios, não garantia de retenção offline.  
- `15s`: intervalo de consulta de mudanças suportada pelo backend.  
Arquivos salvos podem estar aguardando upload. O envio depende do fechamento e do intervalo de write-back. Antes de suspender, desligar, parar ou reiniciar o serviço, aguarde os envios e confira dados importantes no site do Drive.  
Monitorar:  
```  
tail -f "$HOME/.local/state/rclone/gdrive.log"  
 du -sh "$HOME/.cache/rclone"  
 df -h "$HOME"  
   
```  
Ctrl+C encerra o acompanhamento do log, não o serviço.  
Não apagar cache para corrigir OAuth. Pode haver dados ainda não enviados. Não iniciar duas instâncias com o mesmo cache e remotes sobrepostos: a documentação alerta para possível corrupção.  
Excluir arquivos em `~/GoogleDrive` afeta a nuvem. Não executar remoção recursiva nessa pasta. O uso padrão da lixeira no backend não substitui backup.  
Atalhos de pastas exigem cuidado: excluir conteúdo acessado por um atalho na montagem pode atingir a pasta de destino.  
Documentos Google podem aparecer como exportações DOCX/XLSX/PPTX. Não presumir edição bidirecional do documento nativo; para colaboração, preferir navegador.  
Áudio, VMs e bancos de dados: trabalhar localmente e transferir arquivos fechados é uma abordagem mais segura que tratá-los como disco local na nuvem.  
Não há sync, bisync ou backup agendado configurado neste projeto. Não adicionar `rclone sync` como se fosse parte necessária do mount: esse comando pode excluir conteúdo no destino.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**13. Diagnóstico seguro sem reinstalar**  
Começar com observação, não alterações:  
```  
/usr/bin/rclone version  
 /usr/bin/rclone config file  
 systemctl --user status rclone-gdrive.service --no-pager  
 systemctl --user show rclone-gdrive.service -p ActiveState -p SubState -p Result -p NRestarts  
 mountpoint "$HOME/GoogleDrive"  
 stat -c '%a %U %n' "$HOME/.config/rclone/rclone.conf"  
   
```  
Permissões observadas em 26/10: `600`. A presença do arquivo ou de um token não prova que a autenticação funciona.  
Consultar erros recentes, sempre comparando horários:  
```  
journalctl --user -u rclone-gdrive.service --since '15 minutes ago' -n 60 --no-pager  
 tail -n 30 "$HOME/.local/state/rclone/gdrive.log"  
   
```  
O arquivo de log pode mostrar erros antigos mesmo após a recuperação. O journal tem o ciclo do serviço; detalhes do rclone vão principalmente ao arquivo configurado.  
Teste real opcional de acesso:  
```  
/usr/bin/rclone --config="$HOME/.config/rclone/rclone.conf" lsf gdrive: --max-depth 1  
   
```  
Esse teste não altera os arquivos remotos, mas realiza chamadas à API e pode renovar automaticamente o token salvo. Portanto não deve ser descrito como auditoria estritamente sem gravações locais.  
Interpretação:  
- `invalid_grant` novo: investigar autorização, status do app e revogações; não trocar chaves automaticamente.  
- Listagem funciona, mas mount falha: examinar FUSE, diretório e parâmetros do serviço.  
- Pasta vazia sem mount: pode ser apenas o diretório local; não comprova perda remota.  
- Serviço reiniciando sem parar: parar a unidade durante investigação, após cuidados com envios, e corrigir a causa antes de retomar.  
- Erro de rede/DNS: corrigir conectividade, sem reautorizar por tentativa.  
- Erro de client: conferir correspondência projeto/cliente/configuração, sem publicar segredos.  
Não executar `cat rclone.conf`, `config show` ou dumps de ambiente para compartilhar diagnóstico. Não é necessário expor credenciais.  
O script antigo `verificar-gdrive.sh` não é a fonte definitiva: buscava campos em todas as seções, imprimia escapes de cor literalmente, podia mostrar nomes ou erros sem sanitização e chamava de somente leitura um teste que pode renovar token. Este guia substitui seu uso como recomendação principal pelos comandos dirigidos acima.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**14. Comandos de manutenção e reversão**  
Estado:  
```  
systemctl --user status rclone-gdrive.service --no-pager  
   
```  
Iniciar:  
```  
systemctl --user start rclone-gdrive.service  
   
```  
Parar temporariamente, depois de aguardar uploads:  
```  
systemctl --user stop rclone-gdrive.service  
   
```  
Reiniciar, apenas em manutenção planejada:  
```  
systemctl --user restart rclone-gdrive.service  
   
```  
Desativar início automático e parar:  
```  
systemctl --user disable --now rclone-gdrive.service  
   
```  
Reativar:  
```  
systemctl --user enable --now rclone-gdrive.service  
   
```  
Esses controles não exigem apagar cache, configuração ou arquivos da nuvem. Não interromper tarefas de escrita sem planejar.  
Depois de reiniciar o computador, entrar na sessão e validar:  
```  
systemctl --user is-enabled rclone-gdrive.service  
 systemctl --user is-active rclone-gdrive.service  
 mountpoint "$HOME/GoogleDrive"  
   
```  
Confirmar também a abertura da pasta no Dolphin. Esse novo teste pós-reboot ainda não foi confirmado após a publicação OAuth.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**15. Segurança, backup de configuração e GUI**  
Nunca publicar tokens, client secret, códigos de autenticação ou `rclone.conf`, inclusive no repositório de informações.  
Permissões `600` foram confirmadas. Se necessário em outra instalação:  
```  
chmod 600 "$HOME/.config/rclone/rclone.conf"  
   
```  
Isso não criptografa o arquivo nem protege contra acesso pela própria sessão do usuário.  
Antes de manutenção de credenciais, fazer uma cópia protegida, apenas em local privado e fora da montagem:  
```  
(umask 077; cp "$HOME/.config/rclone/rclone.conf" "$HOME/.config/rclone/rclone.conf.backup-$(date +%Y%m%d-%H%M%S)")  
   
```  
Esse comando cria um arquivo local contendo segredos. É uma recomendação opcional, não uma ação confirmada como executada. Não colocar o backup no GitHub; proteger e eliminar cópias antigas conforme planejamento.  
O guia anterior registrava possível exposição de access token em uma sessão antiga. Não há confirmação suficiente para declarar exposição de refresh token nem encerramento de toda a avaliação de risco. Se houver suspeita de acesso por terceiros, revisar autorizações em manutenção planejada.  
RClone Manager:  
- Foi instalado como Flatpak pelo Bazaar no histórico.  
- ID: `io.github.zarestia_dev.rclone-manager`.  
- Integração com a mesma configuração/montagem não foi plenamente validada.  
- Não é necessário para o serviço atual.  
- Não configurar montagem concorrente em `~/GoogleDrive` nem liberar permissões amplas sem diagnóstico.  
- A seleção de `rclone.conf` não equivale a importar backup `.rcman`.  
Não há registro de instalação/teste do Rclone UI neste projeto.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**16. Checklist final e pendências reais**  
Confirmado:  
- rclone do host identificado, versão observada 1.75.2.  
- Remote `gdrive:` preservado.  
- Credenciais próprias já existentes, sem troca nesta manutenção.  
- Site GitHub Pages criado e publicação informada pelo usuário.  
- Branding preenchido; domínio adicionado no campo correto.  
- Nome final: `rclone gdrive Aurora Dan`.  
- App em produção confirmado pelo usuário.  
- Reconexão pelo navegador concluída.  
- Shared Drive respondido com `n`.  
- Teste remoto com configuração explícita funcionou.  
- Serviço reiniciado, estado `active` confirmado.  
- Montagem confirmada em `/var/home/dan/GoogleDrive`.  
Não marcar como realizado sem novo teste:  
- Reboot e validação após a mudança OAuth.  
- Alinhamento editorial do nome nas páginas públicas.  
- Rotação de logs.  
- Auditoria independente do conteúdo remoto das páginas.  
- Integração da GUI com o mesmo remote.  
Não há pendência de instalar rclone, recriar o cliente ou migrar do cliente compartilhado nesta manutenção. A documentação anterior nesse ponto foi superada pelos fatos fornecidos pelo usuário.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
**17. Base documental e histórico desta edição**  
Base interna: `Guia_Google_Drive_Aurora_rclone.md`, edição de 08/10/2026, e saídas/confirmacões fornecidas pelo usuário em 26–27/10/2026. Os resultados locais não foram obtidos por acesso remoto do assistente à máquina.  
Documentação pública consultada:  
- Google Drive no rclone: [https://rclone.org/drive/](https://rclone.org/drive/ "https://rclone.org/drive/")  
- Mount, systemd e cache VFS: [https://rclone.org/commands/rclone_mount/](https://rclone.org/commands/rclone_mount/ "https://rclone.org/commands/rclone_mount/")  
- Público-alvo OAuth e expiração em modo Testing: [https://support.google.com/cloud/answer/15549945?hl=en](https://support.google.com/cloud/answer/15549945?hl=en "https://support.google.com/cloud/answer/15549945?hl=en")  
- Reautenticação: [https://rclone.org/commands/rclone_config_reconnect/](https://rclone.org/commands/rclone_config_reconnect/ "https://rclone.org/commands/rclone_config_reconnect/")  
- GitHub Pages: [https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site "https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site")  
Interfaces e políticas podem mudar. Os comandos de manutenção refletem o serviço e os caminhos deste computador. A edição não promete ausência permanente de revogações nem cria serviços externos automaticamente.  
[Voltar ao mini-sumário](#anchor-18 "#anchor-18")  
