# NameSpace

**Name your macOS desktops. Switch between them in a click.**

NameSpace lives in your menu bar and gives you full control over your virtual desktops — rename them, jump between them instantly, and always know where you are.

---

## Install

### Homebrew (recommended)

```bash
brew tap AduroIdea/namespace
brew install --cask namespace
```

### Manual

Download the latest `NameSpace.dmg` from [Releases](https://github.com/AduroIdea/NameSpace/releases), open it and drag NameSpace to your Applications folder.

---

## Requirements

- macOS 13 Ventura or later
- Accessibility permission (prompted on first launch)

---

## Usage

### Switching desktops
- Click the NameSpace icon in the menu bar to open the dropdown
- Click any desktop name to switch to it instantly

### Renaming desktops
- Open the dropdown and click the ✏️ icon next to any desktop
- Type a new name and press Enter — names persist across restarts

### Display modes
- **Single mode** — shows the current desktop name in the menu bar
- **All mode** — shows every desktop as a separate item; the active one is highlighted with a white border. Right-click any item to open the dropdown.

Switch between modes in **Settings**.

---

## Setup

### Accessibility permission
NameSpace needs Accessibility access to switch desktops using keyboard simulation. On first launch you'll be prompted automatically. You can also grant it in:

**System Settings → Privacy & Security → Accessibility**

### Creating desktops
Open Mission Control (`F3` or `Ctrl+↑`), then click the **+** button in the top-right corner to add new desktops.

### Keyboard shortcuts for desktops
Go to **System Settings → Keyboard → Keyboard Shortcuts → Mission Control** and enable the "Switch to Desktop N" shortcuts. Close System Settings before creating new desktops — otherwise macOS may not register the new shortcuts.

### Recommended Mission Control setting
Disable **"Automatically rearrange Spaces based on most recent use"** in **System Settings → Desktop & Dock → Mission Control** to prevent macOS from reordering your desktops.

---

## Known limitations

| Limitation | Reason |
|---|---|
| Switch may not work if the target desktop has no open apps | macOS has no public API for switching Spaces |
| App Store distribution not possible | Uses private CGS framework APIs |
| Stage Manager may cause unexpected behaviour | Stage Manager changes how macOS groups windows per space |

---

## Built by

[Aduro idea d.o.o.](https://aduroidea.com)
