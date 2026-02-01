# ai-coding

AI-assisted coding development environment built on [devshells](../devshells).

Provides Neovim configurations for various AI coding assistants.

## Quick Start

```bash
nix develop                # Claude-focused (default)
nix develop .#copilot      # GitHub Copilot
nix develop .#codeium      # Codeium (free)
nix develop .#full         # All providers
```

## Available Shells

| Shell | AI Provider | Auth Required |
|-------|-------------|---------------|
| `default` | Claude Code CLI | `ANTHROPIC_API_KEY` |
| `copilot` | GitHub Copilot | `:Copilot auth` |
| `codeium` | Codeium | `:Codeium Auth` |
| `full` | Claude + Copilot | Both |

## Keymaps

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

## Setup

### Claude

Set your API key:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Or add to your shell config.

### Copilot

Run inside Neovim:
```vim
:Copilot auth
```

### Codeium

Run inside Neovim:
```vim
:Codeium Auth
```

## Customization

Edit `flake.nix` to:
- Add more AI providers
- Change default models
- Modify keymaps
- Add project-specific tools

## Dependencies

This flake imports [devshells](../devshells) which provides:
- Base Neovim configuration (Cyberdream theme, LSP, etc.)
- Language modules (Python, TypeScript, Nix, etc.)
- Core tools (git, ripgrep, fzf, etc.)
