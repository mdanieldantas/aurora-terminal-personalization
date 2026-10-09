# Guia: Google Drive API e autenticação OAuth própria no rclone

Data: 9 de outubro de 2026  
Responsável pelo projeto: Marcos Daniel Gomes Dantas  
Ambiente validado: Aurora Linux 44, rclone do host em `/usr/bin/rclone`, versão `1.74.3`.

Este documento registra o procedimento que funcionou nesta sessão: habilitar a Google Drive API, configurar a identidade OAuth, criar um cliente para computador e autenticar o remote `gdrive:` no rclone. Não contém credenciais, tokens, e-mail pessoal nem identificadores reais do projeto.

Resultado confirmado: `rclone lsf gdrive: --max-depth 1` listou arquivos e pastas do Drive. A montagem no Dolphin e a inicialização automática ainda não foram executadas nesta sessão e não são etapas deste documento.

## Mini-sumário

- [1. Objetivo e conceitos](#objetivo)
- [2. Pré-requisitos e custos](#pre-requisitos)
- [3. Selecionar ou criar o projeto](#projeto)
- [4. Habilitar a Google Drive API](#api)
- [5. Configurar a plataforma de autenticação](#plataforma)
- [6. Adicionar o usuário de teste](#testador)
- [7. Criar o cliente OAuth para computador](#cliente)
- [8. Guardar as credenciais e entender o JSON](#credenciais)
- [9. Configurar o remote no rclone](#remote)
- [10. Autorizar pelo navegador](#autorizacao)
- [11. Salvar e validar o acesso](#validacao)
- [12. Diagnóstico dos avisos e erros](#diagnostico)
- [13. Limite de sete dias e uso contínuo](#continuidade)
- [14. Segurança e manutenção](#seguranca)
- [15. Checklist e estado final](#checklist)

<a id="objetivo"></a>
## 1. Objetivo e conceitos

O rclone precisa de autorização para acessar os arquivos privados da conta Google. Neste procedimento usamos OAuth com login pessoal pelo navegador, não uma conta de serviço.

| Elemento | O que significa |
|---|---|
| Projeto Google Cloud | Agrupa a API habilitada e a configuração OAuth. |
| Google Drive API | Interface usada pelo rclone para operações no Drive. |
| Client ID | Identifica o cliente OAuth; não é a senha da conta Google. |
| Client Secret | Credencial do cliente, preenchida no rclone. Deve ser mantida privada. |
| Access token | Autorização temporária para chamadas à API. |
| Refresh token | Permite obter novos access tokens, enquanto continuar válido. |
| Remote `gdrive:` | Nome local da conexão no rclone. Não cria uma nova conta ou novo Drive. |

Criar credenciais próprias reduz a dependência do cliente compartilhado do rclone. A documentação do aplicativo informa que o client ID compartilhado será retirado durante 2026. Isso não aumenta espaço no Drive, não elimina cotas do Google e não garante maior velocidade de transferência. [web:23][web:170]

<a id="pre-requisitos"></a>
## 2. Pré-requisitos e custos

É necessário ter:

- Uma conta Google para acessar o Console e autorizar o Drive.
- Permissão para criar/configurar um projeto Google Cloud.
- Um navegador no computador onde o rclone está sendo configurado.
- rclone instalado e funcionando.

No terminal, verifique:

```bash
command -v rclone
rclone version
rclone listremotes
```

Nesta sessão, o binário já existia em `/usr/bin/rclone`; não foi preciso instalar uma segunda cópia. O aviso de configuração ausente era esperado antes de criar o primeiro remote.

### Sobre pagamento

A oferta de teste com US$ 300 em créditos do Google Cloud não é uma etapa do OAuth. Não inicie o teste ou associe faturamento apenas para seguir este guia.

Não interprete o processo como uma garantia de uso gratuito ilimitado: a documentação consultada informa que o uso padrão da Drive API não tem custo adicional, mas anuncia cobrança por excedentes para mais tarde em 2026. Os detalhes e datas de cobrança devem ser conferidos na documentação oficial vigente. Se aparecer uma exigência de cartão, faturamento ou contratação, pare e revise antes de aceitar. [web:104]

<a id="projeto"></a>
## 3. Selecionar ou criar o projeto

1. Abra o Console do Google Cloud no navegador e entre na sua conta Google.
2. Use o seletor de projetos no topo para selecionar um projeto destinado ao rclone.
3. Caso não exista, escolha a opção de criar um novo projeto e dê um nome identificável, como `rclone pessoal`.
4. Confira que esse projeto permanece selecionado nas próximas etapas.

Não é necessário reproduzir o ID gerado na sessão original. O nome do projeto, o nome do aplicativo e o nome do remote são coisas diferentes.

<a id="api"></a>
## 4. Habilitar a Google Drive API

1. No Console, abra `APIs e serviços → Biblioteca`.
2. Pesquise `Google Drive API`.
3. Selecione exatamente o serviço `drive.googleapis.com`.
4. Confira o projeto selecionado e clique em `Ativar / Enable`.
5. Na página de detalhes, confirme `Status: Ativado`.

Não confunda com:

- Drive Labels API;
- Google Drive Activity API;
- Google Drive MCP;
- Google Cloud Storage.

A identificação `Google Enterprise API` na página não muda qual serviço estamos habilitando: confira o nome `Google Drive API` e o serviço `drive.googleapis.com`.

Na sessão, a tela de métricas ficou sem dados antes do primeiro uso. Isso não impediu a autorização nem o teste posterior. Habilitar a API não cria automaticamente o cliente OAuth. [web:166][web:170]

<a id="plataforma"></a>
## 5. Configurar a plataforma de autenticação

1. Abra `Google Auth Platform / Plataforma de autenticação do Google`.
2. Se aparecer que a plataforma ainda não está configurada, clique em `Começar / Get Started`.
3. Em informações do aplicativo, preencha:
   - Nome do app: por exemplo, `rclone Aurora`.
   - E-mail de suporte: um endereço que você controla.
4. Em `Público / Audience`, selecione `Externo / External` para uso com conta Google pessoal.
5. Em dados de contato, informe seu e-mail.
6. Revise a política apresentada; aceite somente se concordar.
7. Conclua/crie a configuração.

`Interno` restringe o acesso aos membros da organização Google Cloud/Workspace associada ao projeto. Não significa “privado só para mim” e não é a escolha padrão para conta pessoal. [web:114][web:196]

Os nomes de menus podem mudar. A configuração atual distribui as opções entre Identidade/Branding, Público/Audience, Acesso a dados/Data Access e Clientes/Clients.

<a id="testador"></a>
## 6. Adicionar o usuário de teste

Faça esta etapa antes de autenticar no rclone, para evitar o erro encontrado na sessão.

1. Em `Google Auth Platform`, abra `Público / Audience`.
2. Localize `Usuários de teste / Test users`.
3. Clique em `Adicionar usuários`.
4. Informe o e-mail exato da conta cujo Drive será usado no rclone.
5. Salve e confirme que a conta aparece na lista.

O e-mail de suporte ou contato não substitui a inclusão como testador. O modo de teste permite autorização somente aos usuários listados, sujeito às políticas da conta. [web:114][web:196]

<a id="cliente"></a>
## 7. Criar o cliente OAuth para computador

1. Abra `Google Auth Platform → Clientes / Clients`.
2. Clique em `Criar cliente / Create client`.
3. Em tipo de aplicativo, escolha `App para computador / Desktop app`.
4. Dê um nome identificável, por exemplo `rclone Aurora Dan`.
5. Para esta configuração do rclone, não selecione a opção de uso por agente de IA, caso apareça.
6. Clique em `Criar`.
7. Guarde o Client ID e a Chave secreta do cliente sem compartilhá-los.

Não escolha aplicativo Web, chave de API ou conta de serviço para reproduzir este fluxo. O Google documenta o cliente Desktop app para aplicações instaladas em computador. [web:170]

Se houver aviso de propagação das configurações, aguarde caso a autorização não reconheça imediatamente as alterações. Não recrie o projeto sem primeiro verificar o erro.

<a id="credenciais"></a>
## 8. Guardar as credenciais e entender o JSON

O Console pode oferecer um JSON para download. Esse arquivo contém dados do cliente OAuth e deve ficar em armazenamento privado.

Neste procedimento, o rclone recebeu os valores manualmente nos campos `client_id>` e `client_secret>`. Não usamos o JSON como arquivo de conta de serviço.

| Campo no rclone | Valor correto |
|---|---|
| `client_id>` | ID do cliente OAuth criado no Google Cloud. |
| `client_secret>` | Chave secreta do mesmo cliente. |
| `service_account_file>` | Vazio, pois estamos usando login pessoal no navegador. |

O JSON do cliente OAuth e o JSON de uma conta de serviço são arquivos de natureza diferente. Fornecer o primeiro em `service_account_file` não corresponde ao método usado aqui. [web:23][web:170]

Na sessão, a caixa de criação avisou que o segredo não poderia ser consultado novamente depois de fechada. Guarde-o conforme o aviso da interface, preferencialmente em um gerenciador de senhas ou arquivo protegido. Não deixe cópias em repositórios Git, notas públicas ou pastas compartilhadas.

<a id="remote"></a>
## 9. Configurar o remote no rclone

No terminal:

```bash
rclone config
```

Se estiver iniciando do zero, siga esta tabela. Não sobrescreva um remote existente sem necessidade.

| Pergunta | Resposta usada |
|---|---|
| New remote | `n` |
| Nome | `gdrive` |
| Storage | `drive` — Google Drive |
| `client_id>` | Seu Client ID real, somente no terminal. |
| `client_secret>` | Seu Client Secret real, somente no terminal. |
| `scope>` | `1` / `drive`, para leitura e escrita no Drive. |
| `service_account_file>` | Enter, vazio. |
| Edit advanced config? | `n` |
| Use web browser to automatically authenticate? | `y` |

Na lista da sessão, Google Drive era a opção `24`. Prefira identificar pelo nome e digitar `drive`, pois o número pode mudar.

### Escolha consciente do escopo

- `drive`: permite ler, criar, editar, renomear e excluir arquivos, exceto na pasta de dados da aplicação.
- `drive.readonly`: permite listar e baixar, sem enviar, renomear ou excluir.
- `drive.file`: no comportamento documentado do rclone, limita a visualização aos arquivos e pastas criados por ele; não serve para reproduzir o acesso geral pretendido neste guia.

Solicite somente as permissões necessárias. A sessão escolheu acesso completo porque o objetivo posterior é usar o Drive como pasta com escrita no Dolphin. [web:23][web:114]

Se o remote `gdrive` já existir, use a opção de editar o remote em vez de criar outro com o mesmo nome. Para conferir o arquivo usado, execute `rclone config file`, que mostra o caminho sem imprimir seu conteúdo.

<a id="autorizacao"></a>
## 10. Autorizar pelo navegador

1. Após responder `y`, aguarde o navegador abrir.
2. Se não abrir, use o endereço local apresentado pelo rclone no navegador do mesmo computador.
3. Entre na conta adicionada como testadora.
4. Se aparecer aviso de app não verificado, confira que o nome corresponde ao app que você criou.
5. Prossiga pelo botão disponível, como `Continuar`, ou por `Avançado → Ir para o aplicativo`, se essa for a interface exibida.
6. Revise e autorize as permissões solicitadas.
7. Volte ao terminal e aguarde `Got code`.

Só prossiga pelo aviso para seu próprio aplicativo e com as permissões que você reconhece; não generalize esse procedimento para apps desconhecidos. Apps pessoais podem funcionar sem verificação, mas continuam sujeitos às políticas do Google e a limites de usuários. [web:196][web:265]

O rclone utiliza um servidor temporário no endereço de loopback `127.0.0.1`, normalmente na porta `53682`, para receber a resposta OAuth. Não publique essa porta na internet nem faça redirecionamento no roteador. [web:23]

Na sessão, a mensagem sobre Redirect URL apareceu mesmo com cliente Desktop app. A autenticação terminou com `Got code`; não foi necessário criar um cliente Web nem cadastrar manualmente URI de redirecionamento.

Depois de `Got code`, responda:

```text
Configure this as a Shared Drive (Team Drive)?
y/n> n
```

Essa resposta é para acessar o Meu Drive pessoal. Shared Drive é outro cenário, usado com drives compartilhados de organizações; não significa simplesmente uma pasta que alguém compartilhou com você. [web:23]

<a id="validacao"></a>
## 11. Salvar e validar o acesso

O resumo de configuração pode mostrar Client Secret e tokens. Não copie essa tela para um chat, tutorial ou repositório.

Para salvar:

```text
Keep this "gdrive" remote?
y/e/d> y
```

No menu principal:

```text
e/n/d/r/c/s/q> q
```

Depois execute:

```bash
rclone listremotes
rclone lsf gdrive: --max-depth 1
```

O primeiro deve mostrar `gdrive:` e confirma o cadastro local. O segundo testa efetivamente a autenticação/acesso, listando itens do primeiro nível sem modificar arquivos. A listagem bem-sucedida foi o resultado confirmado nesta sessão. [web:23]

Não é necessário reproduzir os nomes de arquivos reais na documentação. Se o Drive estiver vazio, uma listagem vazia sem erro pode ser legítima; não confunda ausência de itens com falha de autenticação.

<a id="diagnostico"></a>
## 12. Diagnóstico dos avisos e erros

### Config file not found — using defaults

Antes do primeiro remote, o aviso de ausência de `rclone.conf` é esperado. Nesta sessão, o caminho observado foi `/var/home/dan/.config/rclone/rclone.conf`. Não copie o usuário `dan` literalmente para outra máquina: confirme com `rclone config file`.

### Erro 403: access_denied — só testadores aprovados

Causa encontrada na sessão: a conta de login ainda não havia sido autorizada como usuária de teste.

Correção:

1. Confirme o projeto correto no Console.
2. Abra `Google Auth Platform → Público → Usuários de teste`.
3. Adicione a conta exata exibida no erro e salve.
4. Se o rclone ainda estiver em `Waiting for code...`, tente recarregar/repetir a autorização no navegador.

Na sessão, adicionar a conta e recarregar a página bastou. Não foi necessário recriar as credenciais ou reiniciar o assistente.

Se o terminal já tiver encerrado/mostrado falha, reinicie o fluxo de configuração. Verifique antes se `gdrive` foi salvo; edite o existente ou crie um novo apenas se ele ainda não existir. [web:196]

### O Google não verificou este app

Depois de adicionar o testador, o bloqueio virou um aviso de app em teste. Esse é o comportamento documentado. Confira identidade e permissões e continue somente se reconhecer o app. [web:196]

### Erro de redirect URI

Confirme que criou um cliente `Desktop app` e usou o Client ID/Secret desse mesmo cliente. Não mude firewall, roteador ou tipo do cliente com base apenas no aviso informativo sobre a URL local.

### Erro de token ou necessidade de nova autorização

Se o remote já existe, a reautorização pode ser feita com:

```bash
rclone config reconnect gdrive:
rclone lsf gdrive: --max-depth 1
```

Se futuramente houver uma montagem ativa, planeje a manutenção: feche arquivos e aguarde uploads antes de mexer em credenciais ou parar serviços. Reconectar não resolve todo erro de quota, rede ou cliente desativado; confira a causa antes. [web:23]

<a id="continuidade"></a>
## 13. Limite de sete dias e uso contínuo

Esta é uma limitação real do estado usado na sessão: app Externo em Teste, com escopo do Drive.

O Google informa que autorizações de testadores expiram sete dias após o consentimento. Se houver refresh token para acesso offline, ele também expira. A exceção para escopos básicos de nome/e-mail/perfil não se aplica ao escopo `drive`. [web:196]

Portanto, não considere a configuração atual uma autenticação permanente para uma montagem automática. Pode ser necessário executar `rclone config reconnect gdrive:` e autorizar novamente após a expiração.

### Opção futura: avaliar publicação para uso pessoal

Publicar o app em produção e submetê-lo à verificação são processos diferentes. O Google prevê exceção de verificação para apps de uso pessoal com menos de 100 usuários, embora possa manter o aviso de app não verificado. Mudar para produção deve ser avaliado conforme as políticas e a interface vigente; não é uma garantia de tokens eternos. [web:196][web:265]

Nesta sessão, não publicamos o app em produção e não validamos autorização de longo prazo. Essa avaliação é uma pendência antes de depender de montagem automática por semanas ou meses.

<a id="seguranca"></a>
## 14. Segurança e manutenção

- Não compartilhe tokens, Client Secret, JSON de credenciais ou `rclone.conf`.
- O Client ID identifica o aplicativo e não equivale à senha da conta; ainda assim, não há necessidade de publicar os valores reais num guia.
- Se você precisar mostrar uma tela de diagnóstico, substitua os valores por `[REMOVIDO]` antes de enviar; não dependa de cortes parciais difíceis de conferir.
- Valores deliberadamente fictícios/mascarados não devem ser tratados automaticamente como credenciais reais expostas.
- Se credenciais reais forem expostas, avalie revogar a autorização na Conta Google e substituir o segredo/cliente pelo Console. Excluir o cadastro local no rclone não equivale a revogar acesso na Conta Google.
- Não habilite criptografia interativa de `rclone.conf` sem planejar como uma futura automação obterá a senha.

Medida adicional de proteção local, não registrada como executada nesta sessão:

```bash
chmod 600 ~/.config/rclone/rclone.conf
```

Execute somente se `rclone config file` confirmar esse caminho. A medida restringe permissões tradicionais ao proprietário, mas não criptografa o arquivo nem protege contra alguém com acesso à sua sessão.

O JSON é uma cópia das credenciais do cliente, não um backup completo do remote autenticado. O rclone mantém sua configuração e tokens separadamente.

<a id="checklist"></a>
## 15. Checklist e estado final

### Confirmado nesta sessão

- [x] Aurora Linux identificado.
- [x] rclone em `/usr/bin/rclone`, versão `1.74.3`, funcionando.
- [x] Google Drive API habilitada: `drive.googleapis.com`.
- [x] Plataforma de autenticação configurada.
- [x] Público Externo, com aplicativo em Teste.
- [x] Cliente OAuth do tipo App para computador criado.
- [x] Client ID e Client Secret informados no rclone.
- [x] Escopo `drive` selecionado.
- [x] Conta de serviço não utilizada.
- [x] Usuário de teste adicionado para resolver o bloqueio 403.
- [x] Autorização no navegador concluída com `Got code`.
- [x] Shared Drive respondido com `n`.
- [x] Remote `gdrive:` salvo.
- [x] Listagem de primeiro nível funcionando.

### Não concluído por este documento

- [ ] Avaliar publicação para uso pessoal/continuidade além de sete dias.
- [ ] Confirmar permissões locais de `rclone.conf`.
- [ ] Montar o Drive em `~/GoogleDrive`.
- [ ] Validar acesso pelo Dolphin.
- [ ] Criar serviço systemd do usuário e testar após reiniciar.

A autenticação e a listagem remota estão concluídas. A montagem e sua automação são uma etapa separada: não execute `sync`, exclusões ou alterações de serviço como parte deste guia.
