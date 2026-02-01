{
  description = "AI-assisted coding development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshells.url = "github:b211u1/base/flake-parts";

    # sops-nix for secret management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, devshells, nixpkgs, sops-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [ devshells.flakeModules.default ];

      perSystem = { config, pkgs, lib, ... }:
        let
          # ============================================
          # SOPS SECRET MANAGEMENT
          # ============================================

          sopsPackages = with pkgs; [ sops age ];

          # Helper script to load secrets from sops-encrypted file
          loadSecretsScript = pkgs.writeShellScript "load-secrets" ''
            SECRETS_FILE="''${SECRETS_FILE:-./secrets/secrets.yaml}"
            if [ -f "$SECRETS_FILE" ]; then
              # Check if age key exists
              AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
              if [ -f "$AGE_KEY_FILE" ]; then
                export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
                # Decrypt and export each secret as an environment variable
                eval "$(${pkgs.sops}/bin/sops --decrypt --output-type dotenv "$SECRETS_FILE" 2>/dev/null || echo "")"
              else
                echo "⚠️  No age key found at $AGE_KEY_FILE"
                echo "   Run: mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt"
              fi
            fi
          '';

          # Common shell hook for sops integration
          sopsShellHook = ''
            # Load secrets from sops-encrypted file if available
            source ${loadSecretsScript}
          '';

          # ============================================
          # AI PROVIDER MODULES
          # ============================================

          claudeModule = {
            name = "claude";

            plugins = with pkgs.vimPlugins; [
              # avante-nvim
              # codecompanion-nvim
            ];

            packages = with pkgs; [
              # claude-code
            ];

            config = ''
              -- Keymaps for Claude Code CLI
              vim.keymap.set("n", "<leader>cc", "<cmd>TermExec cmd='claude'<cr>",
                { desc = "Open Claude Code CLI" })
              vim.keymap.set("n", "<leader>ct", "<cmd>TermExec cmd='claude chat'<cr>",
                { desc = "Claude chat" })

              vim.keymap.set("v", "<leader>ce", function()
                local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."))
                local text = table.concat(lines, "\n")
                vim.fn.setreg("+", text)
                vim.cmd("TermExec cmd='claude \"Explain this code:\\n" .. vim.fn.escape(text, '"\\') .. "\"'")
              end, { desc = "Explain selection with Claude" })

              vim.keymap.set("v", "<leader>cr", function()
                local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."))
                local text = table.concat(lines, "\n")
                vim.fn.setreg("+", text)
                vim.cmd("TermExec cmd='claude \"Review this code and suggest improvements:\\n" .. vim.fn.escape(text, '"\\') .. "\"'")
              end, { desc = "Review selection with Claude" })

              local ok, wk = pcall(require, "which-key")
              if ok then
                wk.add({
                  { "<leader>c", group = "Claude AI" },
                })
              end
            '';
          };

          copilotModule = {
            name = "copilot";

            plugins = with pkgs.vimPlugins; [
              copilot-lua
              copilot-cmp
            ];

            packages = [ ];

            config = ''
              require("copilot").setup({
                panel = {
                  enabled = true,
                  auto_refresh = true,
                  keymap = {
                    jump_prev = "[[",
                    jump_next = "]]",
                    accept = "<CR>",
                    refresh = "gr",
                    open = "<M-CR>",
                  },
                },
                suggestion = {
                  enabled = true,
                  auto_trigger = true,
                  debounce = 75,
                  keymap = {
                    accept = "<M-l>",
                    accept_word = false,
                    accept_line = false,
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<C-]>",
                  },
                },
                filetypes = {
                  yaml = true,
                  markdown = true,
                  help = false,
                  gitcommit = true,
                  gitrebase = false,
                  ["."] = false,
                },
              })

              require("copilot_cmp").setup()

              local cmp = require("cmp")
              local cmp_config = cmp.get_config()
              table.insert(cmp_config.sources, 1, { name = "copilot", priority = 1100 })
              cmp.setup(cmp_config)

              vim.keymap.set("n", "<leader>cp", "<cmd>Copilot panel<cr>", { desc = "Copilot panel" })
              vim.keymap.set("n", "<leader>cs", "<cmd>Copilot status<cr>", { desc = "Copilot status" })
            '';
          };

          codeiumModule = {
            name = "codeium";

            plugins = with pkgs.vimPlugins; [
              codeium-nvim
            ];

            packages = [ ];

            config = ''
              require("codeium").setup({
                enable_chat = true,
              })

              vim.keymap.set("i", "<C-g>", function() return vim.fn["codeium#Accept"]() end,
                { expr = true, desc = "Codeium accept" })
              vim.keymap.set("i", "<M-]>", function() return vim.fn["codeium#CycleCompletions"](1) end,
                { expr = true, desc = "Codeium next" })
              vim.keymap.set("i", "<M-[>", function() return vim.fn["codeium#CycleCompletions"](-1) end,
                { expr = true, desc = "Codeium prev" })
              vim.keymap.set("i", "<C-x>", function() return vim.fn["codeium#Clear"]() end,
                { expr = true, desc = "Codeium clear" })

              vim.keymap.set("n", "<leader>cC", "<cmd>Codeium Chat<cr>", { desc = "Codeium chat" })
            '';
          };

          # ============================================
          # AI PROVIDER CONFIGURATIONS
          # ============================================

          aiProviders = {
            claude = {
              module = claudeModule;
              label = "Claude";
              needsApiKey = true;
              shellHook = ''
                echo "  <leader>cc  Claude Code CLI"
                echo "  <leader>ct  Claude chat"
                echo "  <leader>ce  Explain selection (visual)"
                echo "  <leader>cr  Review selection (visual)"
              '';
            };
            copilot = {
              module = copilotModule;
              label = "GitHub Copilot";
              needsApiKey = false;
              shellHook = ''
                echo "  <M-l>       Accept suggestion"
                echo "  <M-]>/<M-[> Cycle suggestions"
                echo "  <leader>cp  Copilot panel"
                echo ""
                echo "Run :Copilot auth to authenticate"
              '';
            };
            codeium = {
              module = codeiumModule;
              label = "Codeium (Free)";
              needsApiKey = false;
              shellHook = ''
                echo "  <C-g>       Accept suggestion"
                echo "  <M-]>/<M-[> Cycle suggestions"
                echo "  <leader>cC  Codeium chat"
                echo ""
                echo "Run :Codeium Auth to authenticate"
              '';
            };
          };

          # ============================================
          # SHELL LANGUAGE DEFINITIONS
          # ============================================

          # Each entry defines which languages to enable and optional extras
          shellLanguages = {
            python = {
              languages = { python.enable = true; nix.enable = true; };
            };
            typescript = {
              languages = { typescript.enable = true; nix.enable = true; };
            };
            csharp = {
              languages = { csharp.enable = true; nix.enable = true; };
            };
            rust = {
              languages = { rust.enable = true; nix.enable = true; };
            };
            fullstack = {
              languages = { typescript.enable = true; python.enable = true; nix.enable = true; };
            };
            dotnet-fullstack = {
              languages = { csharp.enable = true; typescript.enable = true; nix.enable = true; };
            };
          };

          # ============================================
          # SHELL GENERATOR
          # ============================================

          # Generate a shell for a given language config + AI provider
          mkAIShell = shellName: shellDef: providerName: provider: {
            name = "${shellName}-${providerName}";

            languages = shellDef.languages // {
              ${providerName}.enable = true;
            };

            extraLanguageModules = {
              ${providerName} = provider.module;
            };

            extraPackages = sopsPackages;

            shellHook = ''
              ${sopsShellHook}
              # Set PS1 to reflect the current AI shell
              export PS1="\[\033[1;34m\][${shellName}-${providerName}]\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] $ "
              echo ""
              echo "🤖 ${provider.label} Dev Shell (${shellName} + nix)"
              ${if provider.needsApiKey or false then ''
                if [ -n "''${ANTHROPIC_API_KEY:-}" ]; then
                  echo "✓ ANTHROPIC_API_KEY loaded"
                else
                  echo "⚠️  ANTHROPIC_API_KEY not set - see secrets/README.md"
                fi
              '' else ""}
              echo ""
              echo "Keymaps:"
              ${provider.shellHook}
              echo ""
            '';
          };

          # Generate all provider variants for one language config
          mkProviderVariants = shellName: shellDef:
            lib.mapAttrs' (providerName: provider: {
              name = "${shellName}-${providerName}";
              value = mkAIShell shellName shellDef providerName provider;
            }) aiProviders;

          # Generate all shells: every language × every provider
          generatedShells = lib.foldlAttrs (acc: shellName: shellDef:
            acc // (mkProviderVariants shellName shellDef)
          ) {} shellLanguages;

        in
        {
          devshells.shells = generatedShells // {
            # Default: python + claude
            default = generatedShells.python-claude;
          };
        };
    };
}
