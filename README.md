# SpaceRenamer

macOS menu bar app za preimenovanje i prebacivanje između virtualnih desktopa (Spaces).

---

## Instalacija

1. Otvori `SpaceRenamer.xcodeproj` u Xcodeu
2. `Cmd+R` za pokretanje
3. App se pojavljuje u menu baru (bez ikone u Docku)

---

## Što trebaš omogućiti

### 1. Accessibility (obavezno za switch)

SpaceRenamer treba Accessibility permission da bi mogao slati keyboard eventi za prebacivanje desktopa.

**Kako omogućiti:**

1. Pokreni app — pojavit će se dijalog pri prvom pokretanju
2. Klikni **"Open System Settings"**
3. Idi na **System Settings → Privacy & Security → Accessibility**
4. Pronađi **SpaceRenamer** na listi i uključi toggle

> **Napomena za debug build (Xcode):** Svaki novi build iz Xcodea ima drugačiji binarni hash, pa macOS resetira Accessibility permission. Moraš ga svaki put iznova odobriti. Ovo se ne dogodi s finalnim (arhiviranim) buildom.

---

### 2. Kreiranje desktopa

SpaceRenamer automatski detektira sve desktope. Dodaješ ih u Mission Controlu:

1. Otvori **Mission Control** (`F3` ili `Ctrl+↑`)
2. Klikni **"+"** gumb u gornjem desnom kutu za svaki novi desktop

> **Nema limita** na broj desktopa — SpaceRenamer prikazuje sve.

**Napomena o keyboard shortcutima:** macOS ne kreira automatski "Switch to Desktop N" shortcute za sve desktope u Sequoiji (poznati bug). SpaceRenamer ne ovisi o tim shortcutima — za switch koristi aktivaciju aplikacije koja se nalazi na ciljnom desktopu.

---

### 3. Spaces (Mission Control) postav

SpaceRenamer radi s klasičnim macOS Spacesima. Preporučena konfiguracija:

1. Idi na **System Settings → Desktop & Dock → Mission Control**
2. Uključi **"Displays have separate Spaces"** (ako imaš više monitora)
3. Isključi **"Automatically rearrange Spaces based on most recent use"** — inače macOS mijenja redosljed desktopa i Ctrl+Number shortcuti ne odgovaraju indeksima

---

### 4. App assignment po desktopu

Ako aplikacija prati tebe na sve desktope pri switchu:

1. Desni klik na ikonu app u **Docku**
2. **Options → Assign To**
3. Postavi na **"This Desktop"** umjesto "All Desktops"

---

## Kako koristiti

### Prebacivanje desktopa
- Klikni na naziv desktopa u menu baru → otvori se dropdown
- Klikni na željeni desktop → app se prebaci

### Preimenovanje desktopa
- Otvori dropdown iz menu bara
- Klikni ikonu ✏️ pored desktopa kojeg želiš preimenovati
- Upiši novi naziv → pritisni `Enter`
- Ime se sprema i ostaje i nakon restarta appa

### Postavke prikaza
- Klikni **Settings...** u dropdownu
- **"Current workspace name"** — jedan item u menu baru s imenom aktivnog desktopa
- **"All workspace names"** — jedan item po desktopu u menu baru, bold = aktivni

### Launch at login
- U Settings prozoru uključi **"Launch at login"** da se app automatski pokreće pri prijavi

---

## Poznata ograničenja

| Ograničenje | Razlog |
|---|---|
| Switch ne radi ako na ciljnom desktopu nema otvorenih aplikacija | macOS nema javni API za prebacivanje; koristimo aktivaciju appa kao trigger |
| Keyboard fallback radi samo za prvih 9 desktopa | macOS nema Ctrl+10+ shortcute u Mission Controlu |
| Accessibility permission se resetira na svakom debug buildu | macOS veže permission uz binarni hash |
| App Store distribucija nije moguća | Koristimo private CGS framework API |
| Stage Manager može uzrokovati neočekivano ponašanje | Stage Manager mijenja kako macOS grupira prozore po spacovima |

---

## Distribucija (bez App Storea)

Za trajnu instalaciju bez problema s Accessibility permissionom:

1. U Xcodeu: **Product → Archive**
2. **Distribute App → Direct Distribution → Export**
3. Kopiraj `.app` u `/Applications`
4. Pokreni jednom i odobri Accessibility u System Settings — ostaje trajno
