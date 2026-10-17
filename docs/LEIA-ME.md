# Soniq — como instalar

**Português** · [English](#english)

## Instalação

### Opção 1: um comando (mais fácil)

Abra o **Terminal** (⌘ Espaço → "Terminal"), cole e aperte Enter:

```
curl -fsSL https://raw.githubusercontent.com/webdevpls/soniq/main/install.sh | bash
```

Pronto: o Soniq é instalado em Aplicativos e abre sozinho, sem aviso de segurança.

### Opção 2: DMG pelo Terminal (sem aviso)

```
curl -fL -o ~/Downloads/Soniq.dmg https://github.com/webdevpls/soniq/releases/latest/download/Soniq.dmg && open ~/Downloads/Soniq.dmg
```

Na janela que abrir, arraste o **Soniq** para **Applications**.

### Opção 3: DMG pelo navegador

1. Abra o **Soniq.dmg**. O macOS mostra *"não foi aberto"*: clique em **Concluído**.
2. Vá em **Ajustes do Sistema → Privacidade e Segurança**, role até a seção **Segurança** e clique em **Abrir Mesmo Assim** ao lado de *"Soniq.dmg" foi bloqueado*. Confirme com a sua senha.

   ![Abrir Mesmo Assim](https://raw.githubusercontent.com/webdevpls/soniq/main/docs/screenshots/open-anyway.png)
3. Abra o DMG de novo e arraste o **Soniq** para **Applications** (Aplicativos).
4. Abra o Soniq. Se o aviso aparecer para o app, repita o passo 2.

O ícone aparece na **barra de menus**, no canto superior direito, e não no Dock.

Esse aviso aparece porque o Soniq ainda não é notarizado pela Apple (processo pago). O código é aberto e pode ser conferido no GitHub.

### Permissão de áudio

Na primeira vez que você usar o **boost**, um **efeito** ou o **volume de um app**, o macOS pede a permissão de **Gravação de Áudio do Sistema**. Clique em **Permitir**. O Soniq só processa o som ao vivo: nada é gravado, salvo ou enviado.

### Requisitos

macOS 14.2 ou mais recente · Apple silicon ou Intel

### Desinstalar

Feche o Soniq (botão ⏻ no painel) e apague ele da pasta Aplicativos.

Guia completo: https://github.com/webdevpls/soniq

---

## English

**Easiest:** paste this in Terminal: `curl -fsSL https://raw.githubusercontent.com/webdevpls/soniq/main/install.sh | bash`

**DMG without the prompt:** `curl -fL -o ~/Downloads/Soniq.dmg https://github.com/webdevpls/soniq/releases/latest/download/Soniq.dmg && open ~/Downloads/Soniq.dmg`

**DMG from the browser:** open **Soniq.dmg**. If macOS says it wasn't opened, click **Done**, go to **System Settings → Privacy & Security → Open Anyway**, then drag **Soniq** into **Applications**. Soniq lives in the **menu bar**.

Allow **System Audio Recording** the first time you use boost, an effect or per-app volume. Nothing is recorded or stored.

Requires macOS 14.2 or later · Apple silicon or Intel · Full guide: https://github.com/webdevpls/soniq/blob/main/README.en.md

Developed by **Vision Tech**
