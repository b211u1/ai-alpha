# ai-coding

AI-assisted coding environments built on [devshells](https://github.com/b211u1/base).

Every language shell gets an AI-enhanced variant for each provider. Mix languages and AI tools freely.

## Quick Start

```bash
nix develop                          # python + claude (default)
nix develop .#typescript-copilot     # typescript + copilot
nix develop .#fullstack-claude       # fullstack + claude
nix develop .#rust-codeium           # rust + codeium (free)
```

## Available Shells

Every combination of language and AI provider is generated automatically.

| Shell | Languages | AI Provider |
|-------|-----------|-------------|
| `python-claude` | python, nix | Claude |
| `python-copilot` | python, nix | GitHub Copilot |
| `python-codeium` | python, nix | Codeium |
| `typescript-claude` | typescript, nix | Claude |
| `typescript-copilot` | typescript, nix | GitHub Copilot |
| `typescript-codeium` | typescript, nix | Codeium |
| `csharp-claude` | csharp, nix | Claude |
| `csharp-copilot` | csharp, nix | GitHub Copilot |
| `csharp-codeium` | csharp, nix | Codeium |
| `rust-claude` | rust, nix | Claude |
| `rust-copilot` | rust, nix | GitHub Copilot |
| `rust-codeium` | rust, nix | Codeium |
| `fullstack-claude` | typescript, python, nix | Claude |
| `fullstack-copilot` | typescript, python, nix | GitHub Copilot |
| `fullstack-codeium` | typescript, python, nix | Codeium |
| `dotnet-fullstack-claude` | csharp, typescript, nix | Claude |
| `dotnet-fullstack-copilot` | csharp, typescript, nix | GitHub Copilot |
| `dotnet-fullstack-codeium` | csharp, typescript, nix | Codeium |

## AI Keymaps

### Claude (`<leader>c`)

| Key | Action |
|-----|--------|
| `<leader>cc` | Open Claude Code CLI |
| `<leader>ct` | Claude chat |
| `<leader>ce` | Explain selection (visual) |
| `<leader>cr` | Review selection (visual) |

### Copilot

| Key | Action |
|-----|--------|
| `<M-l>` | Accept suggestion |
| `<M-]>` / `<M-[>` | Cycle suggestions |
| `<leader>cp` | Copilot panel |
| `<leader>cs` | Copilot status |

### Codeium

| Key | Action |
|-----|--------|
| `<C-g>` | Accept suggestion |
| `<M-]>` / `<M-[>` | Cycle suggestions |
| `<leader>cC` | Codeium chat |

## Authentication

### Secret Management (sops-nix)

This project uses [sops](https://github.com/getsops/sops) with age encryption for secure API key management.

**Quick Setup:**

```bash
# 1. Generate age keypair (one-time)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# 2. Get your public key and add to .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
# Edit .sops.yaml with your public key

# 3. Create and encrypt secrets
cp secrets/secrets.yaml.example secrets/secrets.yaml
# Edit secrets.yaml with your ANTHROPIC_API_KEY
sops --encrypt --in-place secrets/secrets.yaml
```

See [secrets/README.md](secrets/README.md) for detailed instructions.

### Claude

The `ANTHROPIC_API_KEY` is loaded automatically from encrypted secrets when entering the shell.

Alternative: set manually in your shell:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Copilot
```vim
:Copilot auth
```

### Codeium
```vim
:Codeium Auth
```

## How It Works

The flake defines two dimensions:

1. **`shellLanguages`** — language combinations (python, typescript, fullstack, etc.)
2. **`aiProviders`** — AI tools (claude, copilot, codeium)

Every shell is generated as `{language}-{provider}` by mapping over both. To add a new language or provider, add one entry and all combinations are created.

## Dependencies

Imports [devshells](https://github.com/b211u1/base) via `flakeModules.default` for base Neovim config, language modules, and core tooling.
