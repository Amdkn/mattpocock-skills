# aspace-mattpocock-skills-adapter

Adapter A'Space (patron Cordis, D-N047) pour le fork `Amdkn/mattpocock-skills`
(amont `mattpocock/skills`, MIT, gel `4ae2317`, version 1.3.2).
Couture **contrat seule** (design D-N048, §1.5) : l'adapter décrit le module,
il ne l'exécute pas et ne modifie rien de l'amont.

## Contenu

| Fichier | Rôle |
|---|---|
| `contract.json` | Inventaire contractuel : 39 skills (nom, seau, chemin, description), 5 scripts shell, versions, posture télémétrie |
| `smoke_test.sh` | Validation structurelle hors-ligne (frontmatter, syntaxe shell, versions, aucune exécution réseau) |
| `README.md` | Ce fichier |

## Le module

Catalogue de skills d'agent pour l'ingénierie réelle (Matt Pocock) : 39 skills
en 5 seaux (engineering 20, productivity 7, misc 4, in-progress 8, deprecated 0).
Chaque skill = un `SKILL.md` (frontmatter `name` + `description`, invocation
utilisateur ou modèle) + un `agents/openai.yaml` (interface). Le plugin Claude
Code (`.claude-plugin/plugin.json`, version 1.3.2) embarque exactement le jeu
promu : 27 skills (engineering + productivity). Les 8 skills `in-progress`
sont publiques par conception mais hors plugin. `ask-matt` est le routeur qui
cartographie les skills atteignables par l'utilisateur.

## Couture contrat seule

L'adapter n'appelle aucune skill et n'exécute aucun script amont. Il expose :

- l'inventaire des skills et leurs interfaces (`contract.json`),
- la preuve structurelle que le module au gel est conforme (`smoke_test.sh`).

Les 5 scripts shell du module (`scripts/link-skills.sh`, `scripts/list-skills.sh`,
`skills/engineering/diagnosing-bugs/scripts/hitl-loop.template.sh`,
`skills/engineering/wizard/template.sh`,
`skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh`) sont
des outils locaux ou des modèles à copier : aucun ne fait d'appel réseau
(voir l'audit télémétrie). `link-skills.sh` crée des liens symboliques vers
`~/.claude/skills` et `~/.agents/skills` : il n'est jamais invoqué par
l'adapter, seulement par un humain ou un harness qui installe le catalogue.

## Télémétrie

Télémétrie zéro par construction : aucun SDK, aucun appel sortant dans le code
exécutable du module. Les URL présentes dans les `SKILL.md` sont des
références de documentation, jamais des appels. Le seul `open_url` du code
(`skills/engineering/wizard/template.sh`, exemple d'étape Stripe) est une
ouverture de navigateur déclenchée par l'utilisateur dans un modèle à
réécrire, pas une télémétrie. Détail : `mattpocock-skills-TELEMETRY-AUDIT.md`.

## Usage

```bash
# Validation hors-ligne (depuis la racine du fork) :
bash aspace-mattpocock-skills-adapter/smoke_test.sh
# Preuve réseau (namespace sans interface) :
unshare -n bash aspace-mattpocock-skills-adapter/smoke_test.sh
```

## Divergence

- Renommage D2 : le fork est `Amdkn/mattpocock-skills` car `Amdkn/skills`
  est le fork d'`anthropics/skills` (intouché). Le chemin du sous-module
  (`01_Forkable/FKB08_Plugins/mattpocock-skills`) est inchangé.
- Le module n'a aucune suite de tests amont (pas de script `test` dans
  `package.json`, aucun fichier de test, aucun job de test en CI). Le
  périmètre H-M3 est la validation statique des skills (frontmatter, syntaxe
  shell, cohérence des versions, structure des seaux).
- La dérive amont est un signal de revisite (§D5 du design D-N048), jamais
  un fast-forward silencieux. Le gel reste `4ae2317`.

Propriétaire : cœur Buzz. Adresse : `fiber:a0:mattpocock-skills`.
