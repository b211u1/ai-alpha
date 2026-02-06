# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix flake-based development environment generator that creates customizable development shells combining language tooling with AI coding assistants. It produces 18 shell variants (6 languages × 3 AI providers) through a cartesian product pattern.

## Commands

```bash
# Enter default shell (python + claude)
nix develop

# Enter specific language + AI provider combination
nix develop .#<language>-<provider>
# Examples: .#typescript-copilot, .#rust-codeium, .#fullstack-claude

# Available languages: python, typescript, csharp, rust, fullstack, dotnet-fullstack
# Available providers: claude, copilot, codeium
```

There are no build, test, or lint commands—this is a declarative configuration project.

## Architecture

### Core Pattern: Matrix Generation

The flake.nix implements a cartesian product to generate all shell combinations:
- **Languages** (6): python, typescript, csharp, rust, fullstack (ts+py+nix), dotnet-fullstack (c#+ts+nix)
- **AI Providers** (3): claude, copilot, codeium
- **Result**: 18 unique development shells + 1 default

### Key Components in flake.nix

1. **AI Provider Modules** (`claudeModule`, `copilotModule`, `codeiumModule`): Define Neovim plugins, packages, and keymaps for each AI assistant

2. **Shell Language Definitions** (`shellLanguages`): Configure language-specific tooling imported from the `devshells` base module

3. **Shell Generators**:
   - `mkAIShell`: Combines a language config with an AI provider
   - `mkProviderVariants`: Maps all providers to a single language
   - `generatedShells`: Applies full cartesian product

4. **Secret Management**: Uses sops-nix with age encryption. `loadSecretsScript` decrypts secrets.yaml and exports API keys as environment variables on shell entry.

### Configuration Flow

```
nix develop .#<lang>-<provider>
    ↓
flake.nix evaluates
    ↓
mkAIShell combines:
  - Language tools from shellLanguages
  - AI provider config from aiProviders
  - SOPS secret loading hook
  - Neovim with language + AI plugins
    ↓
Shell hook executes:
  - Loads encrypted secrets
  - Displays keymaps
  - Validates API keys (Claude only)
```

### External Dependencies

- `devshells` input (from b211u1/base): Provides base language modules and Neovim configuration
- `sops-nix`: Secret management integration
- `flake-parts`: Flake utility library

## Secret Management

Secrets are managed via sops-nix with age encryption. See `secrets/README.md` for setup instructions. The `secrets/secrets.yaml` file (not committed) contains encrypted API keys that are automatically loaded into shell environments.
