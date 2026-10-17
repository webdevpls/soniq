# Política de segurança

**Português** · [English](#english)

## Versões com suporte

Só a versão mais recente do Soniq recebe correções de segurança. Atualize rodando de novo o comando de instalação.

## Como relatar uma vulnerabilidade

**Não abra uma issue pública.** Use o relato privado do GitHub:
[Security → Report a vulnerability](https://github.com/webdevpls/soniq/security/advisories/new).

Inclua a versão do Soniq e do macOS, o passo a passo para reproduzir e o impacto que você observou. Você recebe uma resposta em até 7 dias, e a correção sai em uma nova versão, com crédito a você se quiser.

## O que o Soniq faz e não faz

- Processa o áudio **ao vivo, na memória**. Nunca grava, salva ou envia som.
- **Não faz conexões de rede.** O único acesso à internet é o do `install.sh`, que baixa a release do GitHub.
- Usa a permissão de **Gravação de Áudio do Sistema** só para ajustar o som dos apps que você mudou, ou enquanto o boost ou um efeito estiver ligado.
- Guarda as preferências só no seu Mac (`~/Library/Preferences/io.github.soniq.plist`).

## Verificando um download

Cada release publica o arquivo `SHA256SUMS.txt`. O `install.sh` confere automaticamente a soma SHA-256 e a assinatura do app antes de instalar. Para conferir manualmente:

```sh
shasum -a 256 Soniq.dmg Soniq.zip
codesign --verify --deep --strict --verbose=2 /Applications/Soniq.app
```

---

## English

Only the latest release receives security fixes. **Don't open a public issue** for vulnerabilities: report them privately through
[Security → Report a vulnerability](https://github.com/webdevpls/soniq/security/advisories/new). You'll get a reply within 7 days.

Soniq processes audio live in memory, never records or uploads it, and makes no network connections. Each release ships `SHA256SUMS.txt`; `install.sh` verifies the checksum and the app signature before installing.
