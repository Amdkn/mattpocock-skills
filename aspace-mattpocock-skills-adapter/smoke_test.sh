#!/usr/bin/env bash
# Smoke test de l'adapter aspace-mattpocock-skills-adapter, HORS-LIGNE uniquement.
# Valide la structure du module au gel, jamais un appel réseau, jamais une
# exécution de script amont (bash -n seulement).
# Usage : bash aspace-mattpocock-skills-adapter/smoke_test.sh [CHEMIN_REPO]
#   CHEMIN_REPO : racine du fork (défaut : parent du dossier adapter).
set -u

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
ADAPTER="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. Racine + fichiers de base
[ -f "$ROOT/LICENSE" ] && grep -q "MIT License" "$ROOT/LICENSE" && ok "LICENSE MIT présent" || bad "LICENSE MIT présent"
[ -f "$ROOT/package.json" ] && ok "package.json présent" || bad "package.json présent"
[ -f "$ROOT/.claude-plugin/plugin.json" ] && ok "plugin.json présent" || bad "plugin.json présent"
[ -f "$ADAPTER/contract.json" ] && ok "contract.json présent" || bad "contract.json présent"

# 2. contract.json : JSON valide, 39 skills
if python3 -c "import json,sys; json.load(open('$ADAPTER/contract.json'))" 2>/dev/null; then
  ok "contract.json JSON valide"
else
  bad "contract.json JSON valide"
fi
N_CONTRACT=$(python3 -c "import json; print(len(json.load(open('$ADAPTER/contract.json'))['skills']))" 2>/dev/null || echo 0)
N_DISK=$(find "$ROOT/skills" -name SKILL.md | wc -l)
[ "$N_CONTRACT" = "$N_DISK" ] && [ "$N_CONTRACT" = "39" ] && ok "inventaire 39 skills (contrat = disque)" || bad "inventaire 39 skills (contrat=$N_CONTRACT disque=$N_DISK)"

# 3. Chaque skill du contrat existe sur disque, frontmatter name + description
MISSING=0
while IFS= read -r path; do
  [ -f "$ROOT/$path/SKILL.md" ] || { MISSING=$((MISSING+1)); echo "  manquant: $path"; }
done < <(python3 -c "import json; [print(s['path']) for s in json.load(open('$ADAPTER/contract.json'))['skills']]")
[ "$MISSING" = 0 ] && ok "39 chemins de skills présents" || bad "39 chemins de skills présents ($MISSING manquants)"
NO_NAME=$(python3 - "$ROOT" <<'PYEOF'
import re
from pathlib import Path
import sys
root = Path(sys.argv[1])
bad = 0
for p in sorted(root.rglob("skills/**/SKILL.md")):
    text = p.read_text()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    fm = dict(l.split(":", 1) for l in m.group(1).splitlines() if ":" in l) if m else {}
    if not fm.get("name", "").strip() or not fm.get("description", "").strip():
        bad += 1
        print(f"  frontmatter incomplet: {p}")
print(bad)
PYEOF
)
[ "$NO_NAME" = "0" ] && ok "frontmatter name+description sur 39 SKILL.md" || bad "frontmatter name+description ($NO_NAME incomplets)"

# 4. Syntaxe shell des 5 scripts (bash -n, jamais exécutés)
SH_FAIL=0
for f in $(find "$ROOT/scripts" "$ROOT/skills" -name "*.sh" -not -path "*/node_modules/*"); do
  bash -n "$f" 2>/dev/null || { SH_FAIL=$((SH_FAIL+1)); echo "  bash -n échoue: $f"; }
done
[ "$SH_FAIL" = 0 ] && ok "syntaxe shell : 5 scripts bash -n propres" || bad "syntaxe shell ($SH_FAIL échecs)"

# 5. Versions cohérentes : package.json == plugin.json == contrat (1.3.2)
V_PKG=$(python3 -c "import json; print(json.load(open('$ROOT/package.json'))['version'])" 2>/dev/null)
V_PLG=$(python3 -c "import json; print(json.load(open('$ROOT/.claude-plugin/plugin.json'))['version'])" 2>/dev/null)
V_CTR=$(python3 -c "import json; print(json.load(open('$ADAPTER/contract.json'))['version'])" 2>/dev/null)
[ "$V_PKG" = "$V_PLG" ] && [ "$V_PLG" = "$V_CTR" ] && [ "$V_CTR" = "1.3.2" ] && ok "versions 1.3.2 cohérentes (package/plugin/contrat)" || bad "versions cohérentes (pkg=$V_PKG plg=$V_PLG ctr=$V_CTR)"

# 6. Aucun appel réseau dans l'adapter lui-même
if grep -rniE "curl|wget|https?://" "$ADAPTER" --include="*.sh" --include="*.json" | grep -v "contract.json" >/dev/null 2>&1; then
  bad "aucun appel réseau dans l'adapter"
else
  ok "aucun appel réseau dans l'adapter"
fi

# 7. Gel : HEAD du clone = 4ae2317 (si dépôt git présent)
if [ -d "$ROOT/.git" ]; then
  HEAD=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)
  [ "$HEAD" = "4ae2317ddb22b046e26455e4f9c9b3aaaf62212d" ] && ok "HEAD du clone = gel 4ae2317" || bad "HEAD du clone = gel 4ae2317 (HEAD=$HEAD)"
else
  ok "pas de .git (vérification du gel non applicable)"
fi

echo "----"
echo "smoke: pass $PASS, fail $FAIL"
[ "$FAIL" = 0 ]
