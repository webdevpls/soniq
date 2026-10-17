# Como contribuir com o Soniq

Obrigado por ajudar a melhorar o Soniq!

## Relatando bugs

[Abra uma issue](https://github.com/webdevpls/soniq/issues/new?template=bug_report.md) e inclua:

- A versão do macOS e o modelo do Mac (Apple silicon ou Intel)
- O dispositivo de saída (alto-falantes do Mac, AirPods, interface USB…)
- O que você fez, o que esperava e o que aconteceu
- O app afetado, se o problema for com um app específico

Logs ajudam muito. Rode o Soniq com diagnóstico e anexe o arquivo:

```sh
open --env SONIQ_DEBUG=1 --stderr ~/Desktop/soniq.log /Applications/Soniq.app
```

## Sugerindo recursos

[Sugira um recurso](https://github.com/webdevpls/soniq/issues/new?template=feature_request.md).
Descreva primeiro o problema e depois a solução que você imagina.

## Pull requests

1. Faça um fork do repositório e crie uma branch a partir da `main`.
2. Compile com `./scripts/build-app.sh` e teste a mudança no app de verdade.
3. Siga o estilo dos arquivos ao redor: SwiftUI, views pequenas, comentários só onde o motivo não é óbvio.
4. Código na thread de áudio em tempo real (`AppTap.render`, `EffectsProcessor.process`, `Limiter`) não pode alocar memória, usar locks nem chamar Objective-C.
5. Textos novos da interface entram em inglês no código e com tradução em `Resources/pt-BR.lproj/Localizable.strings`.
6. Explique o que mudou e como você testou.

Ao contribuir, você concorda que a sua contribuição é licenciada sob a [GPL-3.0](LICENSE).
