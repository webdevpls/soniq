# Histórico de versões

Todas as mudanças importantes do Soniq ficam registradas aqui. O projeto segue o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.1] - 2026-10-17

### Novidades
- Botão de silenciar o microfone ao lado do controle do mic.
- Trava do nível do microfone: apps de chamada (Meet, WhatsApp, Zoom…) não conseguem mais aumentar o volume do mic sozinhos. Ligada por padrão.

### Correções
- Levar o microfone ou o volume até o zero agora silencia de verdade. Antes, o mic do MacBook ainda captava som a -32 dB.
- Reativar o microfone a partir do zero volta o nível para 50%, em vez de continuar mudo.

## [0.1.0] - 2026-10-17

Primeira versão pública.

### Novidades
- Boost de volume até 200% com limitador.
- Volume, mudo e balanço esquerda/direita por app.
- Efeitos sonoros: Graves+, Festa, Aquário, Show, Outra Sala, No Carro, Rádio, 3D Amplo, Voz, Noite e Cinema, com intensidade, graves e agudos.
- Troca do dispositivo de saída.
- Nível do microfone, troca de entrada e "Manter este microfone".
- Teste de fone e AirPods: esquerdo/direito, varredura estéreo, frequência, graves e fase.
- Ajustes dentro do painel para esconder seções, abrir ao iniciar e escolher o idioma.
- Interface em português e inglês.
- Interface nativa em SwiftUI com Liquid Glass no macOS 26.

[0.1.1]: https://github.com/webdevpls/soniq/releases/tag/v0.1.1
[0.1.0]: https://github.com/webdevpls/soniq/releases/tag/v0.1.0
