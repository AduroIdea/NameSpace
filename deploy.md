# Deploy upute za NameSpace

---

## 1. Svakodnevne izmjene (bez novog releasea)

Napraviš izmjenu u kodu, pa:

```bash
git add NameSpace/UI/SpaceListView.swift   # dodaj točno taj file koji si mijenjao
git commit -m "Opis što si promijenio"
git push
```

Primjer:
```bash
git add NameSpace/UI/HelpView.swift
git commit -m "Update help text for keyboard shortcuts"
git push
```

---

## 2. Novi release (nova verzija za korisnike)

### Korak 1 — Ažuriraj broj verzije

U `project.yml` promijeni `CFBundleShortVersionString` i `CFBundleVersion`:

```yaml
CFBundleShortVersionString: "1.1"
CFBundleVersion: "2"
```

Regeneriraj projekt:
```bash
xcodegen generate
```

### Korak 2 — Commitaj izmjene

```bash
git add .
git commit -m "Bump version to 1.1"
git push
```

### Korak 3 — Arhiviraj app

```bash
xcodebuild archive \
  -project /Users/ivan/development/random/NameSpace/NameSpace.xcodeproj \
  -scheme NameSpace \
  -configuration Release \
  -archivePath /Users/ivan/Desktop/NameSpace.xcarchive
```

### Korak 4 — Exportaj app

```bash
xcodebuild -exportArchive \
  -archivePath /Users/ivan/Desktop/NameSpace.xcarchive \
  -exportPath /Users/ivan/Desktop/NameSpace-export \
  -exportOptionsPlist /Users/ivan/Desktop/ExportOptions.plist
```

### Korak 5 — Notariziraj

Zapakiraj u zip:
```bash
ditto -c -k --keepParent /Users/ivan/Desktop/NameSpace-export/NameSpace.app /Users/ivan/Desktop/NameSpace.zip
```

Pošalji na notarizaciju (čeka automatski):
```bash
xcrun notarytool submit /Users/ivan/Desktop/NameSpace.zip \
  --apple-id "support@aduro.hr" \
  --password "XXXX-XXXX-XXXX-XXXX" \
  --team-id "QQD745SZ96" \
  --wait
```

> App-specific lozinku generiraš na appleid.apple.com → Sign-In and Security → App-Specific Passwords

Kad dobiješ `status: Accepted`, stapleaj ticket:
```bash
xcrun stapler staple /Users/ivan/Desktop/NameSpace-export/NameSpace.app
```

Provjeri je li sve ok:
```bash
spctl -a -vvv -t execute /Users/ivan/Desktop/NameSpace-export/NameSpace.app
# Treba pisati: source=Notarized Developer ID
```

### Korak 6 — Napravi DMG

```bash
hdiutil create -volname "NameSpace" \
  -srcfolder /Users/ivan/Desktop/NameSpace-export/NameSpace.app \
  -ov -format UDZO \
  /Users/ivan/Desktop/NameSpace-1.1.dmg
```

> Promijeni `1.1` u stvarni broj verzije.

### Korak 7 — Objavi GitHub Release

```bash
gh release create v1.1 /Users/ivan/Desktop/NameSpace-1.1.dmg \
  --repo AduroIdea/NameSpace \
  --title "NameSpace 1.1" \
  --notes "Opis što je novo u ovoj verziji."
```

### Korak 8 — Ažuriraj Homebrew tap

Izračunaj SHA256 novog DMG-a:
```bash
shasum -a 256 /Users/ivan/Desktop/NameSpace-1.1.dmg
```

Uredi tap file:
```bash
nano ~/development/homebrew-namespace/Casks/namespace.rb
# ili otvori u editoru
```

Promijeni `version` i `sha256`:
```ruby
cask "namespace" do
  version "1.1"
  sha256 "NOVI_SHA256_HASH_OVDJE"
  ...
end
```

Commitaj i pushaj tap:
```bash
git -C ~/development/homebrew-namespace add Casks/namespace.rb
git -C ~/development/homebrew-namespace commit -m "Update namespace to 1.1"
git -C ~/development/homebrew-namespace push
```

Korisnici koji imaju tap instaliran dobit će update automatski s:
```bash
brew upgrade --cask namespace
```

---

## Brzi pregled koraka za novi release

| Korak | Naredba |
|---|---|
| Bump verzija | Uredi `project.yml`, pokreni `xcodegen generate` |
| Commit + push | `git add . && git commit -m "..." && git push` |
| Archive | `xcodebuild archive ...` |
| Export | `xcodebuild -exportArchive ...` |
| Notarizacija | `notarytool submit ... --wait` + `stapler staple` |
| DMG | `hdiutil create ...` |
| GitHub Release | `gh release create ...` |
| Homebrew tap | Ažuriraj `namespace.rb` + push |
