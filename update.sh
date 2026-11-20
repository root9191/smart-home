#!/bin/bash
set -euo pipefail

# Verzeichnis dieses Skripts (Projektroot), damit es von überall funktioniert
cd "$(dirname "$0")"

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/smart-home@chlumskyvaclav.gmail.com"
BUILD_DIR="build/smart-home@chlumskyvaclav.gmail.com"

# 1. Sicherheitscheck: keine uncommitteten Änderungen
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Fehler: Es gibt uncommittete Änderungen."
    echo "Bitte zuerst committen oder mit 'git stash' sichern."
    exit 1
fi

# 2. Neue Commits vom Original holen
echo "==> Hole Änderungen vom Original (upstream)"
git fetch upstream

# 3. Eigene Änderungen auf den neuen Stand setzen
echo "==> Rebase auf upstream/main"
if ! git rebase upstream/main; then
    echo ""
    echo "Rebase mit Konflikten gestoppt."
    echo "Konflikte lösen, dann 'git add <datei>' und 'git rebase --continue'."
    echo "Oder mit 'git rebase --abort' abbrechen. Danach Skript erneut starten."
    exit 1
fi

# 4. Fork aktualisieren (nur origin, nie upstream)
echo "==> Push nach origin (Fork)"
git push origin main --force-with-lease

# 5. Neu bauen (nacheinander, nicht parallel)
echo "==> Build"
make clean
make build

# 6. Build-Ergebnis in das lokale Extension-Verzeichnis kopieren
echo "==> Kopiere nach $EXT_DIR"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp -r "$BUILD_DIR"/. "$EXT_DIR"/

echo ""
echo "Fertig. GNOME-Shell neu laden (Wayland: abmelden und anmelden)."