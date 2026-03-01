# claude-code-python-workspace

Workspace de referência para projetos Python com Claude Code.
Define padrões, skills e agents que são herdados por todos os projetos filhos.

---

## Estrutura

```
.claude/
  skills/        # Capacidades atômicas — invocadas diretamente pelo agente
  agents/        # Orquestradores multi-step — combinam skills para entregar valor
  commands/      # Gerado pelo sync — é o que o Claude Code lê
docs/
  STANDARDS.md   # Padrões de código Python (ruff, mypy, pytest)
  BRANCHING.md   # Estratégia de branches e merge
  CLOUD_RUN.md   # Setup de Cloud Run com Workload Identity Federation
  SECRETS.md     # Gestão de secrets no GitHub Actions e GCP
  WORKFLOW.md    # Fluxo completo: spec → plan → implement → test → commit → pr → deploy
scripts/
  sync-to-project.sh  # Propaga skills e agents para um projeto filho
CLAUDE.md        # Papel do agente e workflow obrigatório
Dockerfile       # Multi-stage build (builder + production) para Cloud Run
pyproject.toml   # Template de configuração Python 3.12+
```

---

## Skills

Capacidades atômicas que o agente executa diretamente.

| Skill | Descrição |
|-------|-----------|
| `/commit` | Cria um Conventional Commit seguro (escaneia secrets antes) |
| `/test` | Roda pytest + mypy + ruff e reporta resultados |
| `/review` | Revisão de código do branch atual vs base |
| `/setup-secrets` | Cria GitHub Actions secrets via API (sem precisar de `gh` autenticado) |
| `/ci-watch` | Monitora workflows via GitHub API até todos finalizarem |

## Agents

Orquestradores que combinam múltiplos passos para entregar um resultado completo.

| Agent | Descrição |
|-------|-----------|
| `/spec` | Lê o task e produz especificação técnica formal em `docs/specs/` |
| `/plan` | Explora o código, projeta a implementação e entra em modo de aprovação |
| `/pr` | Verifica CI, abre PR com descrição completa e linka issues |
| `/deploy` | Confirma → triggera deploy → monitora → verifica `/health` → reporta URL |

---

## Workflow Obrigatório

```
/spec → /plan → implement → /test → /commit → /pr → /deploy
```

Nunca pular etapas. Ver **docs/WORKFLOW.md** para detalhes.

---

## Como usar em um projeto novo

### 1. Propagar skills e agents

```bash
cd claude-code-python-workspace
./scripts/sync-to-project.sh /path/to/novo-projeto
```

Isso copia todos os skills e agents para `.claude/commands/` do projeto filho.

### 2. Criar CLAUDE.md no projeto filho

O `CLAUDE.md` do projeto deve referenciar este workspace e conter o contexto específico do projeto (nome do serviço, URL, projeto GCP, etc). Ver `demo-app/CLAUDE.md` como exemplo.

### 3. Manter atualizado

No projeto filho, rode sempre que o workspace for atualizado:

```bash
./scripts/sync-workspace.sh
```

---

## Como atualizar o workspace

Qualquer melhoria em skills ou agents deve ser feita **aqui** e propagada para os projetos filhos via `sync-workspace.sh`.

```bash
# 1. Edite o skill/agent desejado
vim .claude/skills/commit.md

# 2. Commit e push
/commit

# 3. Em cada projeto filho:
./scripts/sync-workspace.sh
```

---

## Documentação

| Doc | Conteúdo |
|-----|----------|
| [STANDARDS.md](docs/STANDARDS.md) | Python 3.12+, ruff, mypy, pytest, cobertura ≥ 80% |
| [BRANCHING.md](docs/BRANCHING.md) | main / develop / feature / fix / chore |
| [CLOUD_RUN.md](docs/CLOUD_RUN.md) | GCP, Artifact Registry, Workload Identity, deploy |
| [SECRETS.md](docs/SECRETS.md) | GitHub Actions secrets, GCP Secret Manager |
| [WORKFLOW.md](docs/WORKFLOW.md) | Fluxo completo task → produção |
