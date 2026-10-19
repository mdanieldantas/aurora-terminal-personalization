# Corrigir tela preta no Cameractrls — Aurora Linux

## Sintoma

A prévia da webcam fica preta no Cameractrls, embora a câmera funcione em outros aplicativos. Este guia cobre o caso em que o Cameractrls foi instalado como Flatpak no Aurora.

## Solução temporária

Feche o Cameractrls e execute no terminal:

```bash
flatpak run --env=LIBGL_ALWAYS_SOFTWARE=1 hu.irl.cameractrls
```

Se a imagem aparecer, o problema está relacionado à renderização da prévia do aplicativo. Esse comando só aplica a opção durante essa execução.

## Manter a correção

Para iniciar o Cameractrls normalmente pelo menu e manter a opção nas próximas aberturas:

```bash
flatpak override --user --env=LIBGL_ALWAYS_SOFTWARE=1 hu.irl.cameractrls
```

Depois, feche e abra o app pelo menu.

## Desfazer a alteração

```bash
flatpak override --user --unset-env=LIBGL_ALWAYS_SOFTWARE hu.irl.cameractrls
```

## Observação

A renderização por software pode aumentar o uso do processador. O ajuste é aplicado apenas ao Cameractrls do usuário atual. Se o comando temporário não funcionar, confirme a instalação com:

```bash
flatpak list --app | grep -i cameractrls
```
