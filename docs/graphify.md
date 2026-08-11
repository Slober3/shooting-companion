# Graphify codebase graph

Shooting Companion pins Graphify `0.9.40` as a developer and CI tool. It builds
a local AST-only knowledge graph; it is not shipped in the Android app, opens no
runtime network connection and never indexes private validation media.

## First setup

From the repository root in PowerShell:

```powershell
.\tools\setup_graphify.ps1 -InstallCli
```

The script verifies the exact CLI version, installs the Codex skill and
repository instructions, installs post-commit/post-checkout hooks plus the
Graphify merge driver, generates the code-only graph and normalizes volatile
checkout metadata.

Without `-InstallCli`, the script fails when Graphify is missing or has another
version. Installing requires `uv`; normal graph updates need no API key or LLM.

## Daily use

Ask narrow questions before opening broad source trees:

```powershell
graphify query "Hoe wordt een bevestigde reeks aan een drill gekoppeld?"
graphify explain "GuidedDrillRunnerScreen"
graphify path "TrainingToolsScreen" "ShootingRepository" --undirected
graphify affected "ScoreEngine" --depth 2
```

After code changes:

```powershell
graphify update .
python tools/normalize_graphify_output.py
python tools/verify_graphify.py
```

`AGENTS.md` makes this query-first workflow explicit for Codex. Hooks keep the
local graph current after commits and checkouts; the normalizer removes absolute
paths, file mtimes and self-referential commit metadata afterward.

The generated code graph is undirected. Use `--undirected` for path searches so
the result follows relationships regardless of their extraction direction.

## Versioned and local output

Committed, normalized files:

- `graphify-out/graph.json` — queryable nodes and relationships;
- `graphify-out/manifest.json` — content hashes with normalized mtimes;
- `graphify-out/.graphify_root` — portable `.` marker;
- `graphify-out/.graphify_analysis.json` — deterministic communities when a
  repeated generation is byte-identical;
- `graphify-out/.graphify_labels.json` — deterministic local labels used by
  focused queries and symbol smoke-tests.

Caches, memory/reflection data, wiki output, HTML visualizations and temporary
files are ignored. `.graphifyignore` additionally excludes generated database
code, local SDKs, build products, third-party licenses, APKs, backups and all
private validation locations.

## CI and troubleshooting

CI installs exactly `graphifyy==0.9.40`, performs an AST-only update, normalizes
the result and rejects a dirty durable graph. It also checks required 0.8
symbols, excluded path prefixes, representative query/explain/path commands and
multigraph diagnostics.

- **Graph is stale:** run the update and normalizer from the repository root.
- **Wrong Graphify version:** rerun setup with `-InstallCli`; it upgrades the uv
  tool to the pinned version.
- **Hook missing:** run `graphify hook status`, then rerun setup.
- **Merge conflict in `graph.json`:** ensure the merge driver is installed,
  resolve source first and regenerate/normalize the graph.
- **Unexpected private or generated path:** extend `.graphifyignore`, regenerate
  with `graphify extract . --code-only --force`, then rerun both verifiers.
