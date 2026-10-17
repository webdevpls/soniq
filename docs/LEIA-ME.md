# Soniq — como instalar

**Português** · [English](#english)

## Instalação

1. Abra o **Soniq-x.y.z.dmg**.
2. Arraste o **Soniq** para a pasta **Applications** (Aplicativos) que aparece na janela.
3. Abra o Soniq pela pasta Aplicativos ou pelo Spotlight (⌘ Espaço → "Soniq"). O ícone aparece na **barra de menus**, no canto superior direito, e não no Dock.

### "O macOS não pode verificar o desenvolvedor"

O Soniq ainda não é notarizado pela Apple. Na primeira vez:

1. Tente abrir o Soniq e feche o aviso.
2. Vá em **Ajustes do Sistema → Privacidade e Segurança**.
3. Role até o fim e clique em **Abrir Mesmo Assim** ao lado do Soniq.

Só é preciso fazer isso uma vez. Pelo terminal: `xattr -dr com.apple.quarantine /Applications/Soniq.app`

### Permissão de áudio

Na primeira vez que você usar o **boost**, um **efeito** ou o **volume de um app**, o macOS pede a permissão de **Gravação de Áudio do Sistema**. Clique em **Permitir**. O Soniq só processa o som ao vivo: nada é gravado, salvo ou enviado.

### Requisitos

macOS 14.2 ou mais recente · Apple silicon ou Intel

### Desinstalar

Feche o Soniq (botão ⏻ no painel) e apague ele da pasta Aplicativos.

Guia completo: https://github.com/webdevpls/soniq

---

## English

1. Open **Soniq-x.y.z.dmg** and drag **Soniq** into **Applications**.
2. Open Soniq. Its icon appears in the **menu bar**, not in the Dock.
3. If macOS can't verify the developer, go to **System Settings → Privacy & Security** and click **Open Anyway** (once).
4. Allow **System Audio Recording** the first time you use boost, an effect or per-app volume. Nothing is recorded or stored.

Requires macOS 14.2 or later · Apple silicon or Intel · Full guide: https://github.com/webdevpls/soniq/blob/main/README.en.md

Developed by **Vision Tech**
