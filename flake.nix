{
  description = "AI-assisted coding development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    # Import the devshells flake
    # Change this to your actual repo URL when published
    devshells.url = "github:b211u1/base";
  };

  outputs = inputs@{ flake-parts, devshells, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [ devshells.flakeModules.default ];

      perSystem = { config, pkgs, lib, ... }: 
        let
          # AI language module - adds AI coding assistants to Neovim
          claudeModule = {
            name = "claude";
            
            plugins = with pkgs.vimPlugins; [
              # Avante - Cursor-like AI pane (supports Claude, GPT, local models)
              # avante-nvim
              
              # CodeCompanion - flexible chat + inline + agents
              # codecompanion-nvim
            ];
            
            packages = with pkgs; [
              # Claude Code CLI (if/when available in nixpkgs)
              # claude-code
            ];
            
            config = ''
              -- ============================================
              -- CLAUDE AI CONFIGURATION
              -- ============================================
              
              -- Avante setup (Cursor-like experience)
              -- Uncomment when avante-nvim is available
              -- require("avante").setup({
              --   provider = "claude",
              --   claude = {
              --     endpoint = "https://api.anthropic.com",
              --     model = "claude-sonnet-4-20250514",
              --     temperature = 0,
              --     max_tokens = 4096,
              --   },
              --   behaviour = {
              --     auto_suggestions = false,
              --     auto_set_highlight_group = true,
              --     auto_set_keymaps = true,
              --   },
              --   mappings = {
              --     ask = "<leader>aa",
              --     edit = "<leader>ae",
              --     refresh = "<leader>ar",
              --     toggle = {
              --       default = "<leader>at",
              --       debug = "<leader>ad",
              --       hint = "<leader>ah",
              --     },
              --   },
              -- })
              
              -- CodeCompanion setup (more flexible)
              -- Uncomment when codecompanion-nvim is available
              -- require("codecompanion").setup({
              --   adapters = {
              --     anthropic = function()
              --       return require("codecompanion.adapters").extend("anthropic", {
              --         schema = {
              --           model = { default = "claude-sonnet-4-20250514" },
              --         },
              --       })
              --     end,
              --   },
              --   strategies = {
              --     chat = { adapter = "anthropic" },
              --     inline = { adapter = "anthropic" },
              --     agent = { adapter = "anthropic" },
              --   },
              -- })
              
              -- Keymaps for AI assistance
              vim.keymap.set("n", "<leader>cc", "<cmd>TermExec cmd='claude'<cr>", 
                { desc = "Open Claude Code CLI" })
              vim.keymap.set("n", "<leader>ct", "<cmd>TermExec cmd='claude chat'<cr>", 
                { desc = "Claude chat" })
              
              -- Quick prompts
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
              
              -- Which-key group for AI
              local ok, wk = pcall(require, "which-key")
              if ok then
                wk.add({
                  { "<leader>c", group = "Claude AI" },
                })
              end
            '';
          };

          # Copilot module - GitHub Copilot integration
          copilotModule = {
            name = "copilot";
            
            plugins = with pkgs.vimPlugins; [
              copilot-lua
              copilot-cmp
            ];
            
            packages = [ ];
            
            config = ''
              -- ============================================
              -- GITHUB COPILOT CONFIGURATION
              -- ============================================
              
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
              
              -- Copilot-cmp integration
              require("copilot_cmp").setup()
              
              -- Add Copilot to cmp sources
              local cmp = require("cmp")
              local cmp_config = cmp.get_config()
              table.insert(cmp_config.sources, 1, { name = "copilot", priority = 1100 })
              cmp.setup(cmp_config)
              
              -- Keymaps
              vim.keymap.set("n", "<leader>cp", "<cmd>Copilot panel<cr>", { desc = "Copilot panel" })
              vim.keymap.set("n", "<leader>cs", "<cmd>Copilot status<cr>", { desc = "Copilot status" })
              vim.keymap.set("n", "<leader>ce", "<cmd>Copilot enable<cr>", { desc = "Copilot enable" })
              vim.keymap.set("n", "<leader>cd", "<cmd>Copilot disable<cr>", { desc = "Copilot disable" })
            '';
          };

          # Codeium module - Free AI completion alternative
          codeiumModule = {
            name = "codeium";
            
            plugins = with pkgs.vimPlugins; [
              codeium-nvim
            ];
            
            packages = [ ];
            
            config = ''
              -- ============================================
              -- CODEIUM CONFIGURATION (Free alternative)
              -- ============================================
              
              require("codeium").setup({
                enable_chat = true,
              })
              
              -- Keymaps
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

        in
        {
          devshells.shells = {
            # Default: Claude-focused AI coding
            default = {
              name = "ai-claude";
              languages = {
                python.enable = true;
                typescript.enable = true;
                nix.enable = true;
                claude.enable = true;
              };
              extraLanguageModules = {
                claude = claudeModule;
              };
              shellHook = ''
                echo "🤖 AI Coding Environment (Claude)"
                echo ""
                echo "AI Keymaps:"
                echo "  <leader>cc  Open Claude Code CLI"
                echo "  <leader>ct  Claude chat"
                echo "  <leader>ce  Explain selection (visual)"
                echo "  <leader>cr  Review selection (visual)"
                echo ""
              '';
            };

            # Copilot-based shell
            copilot = {
              name = "ai-copilot";
              languages = {
                python.enable = true;
                typescript.enable = true;
                nix.enable = true;
                copilot.enable = true;
              };
              extraLanguageModules = {
                copilot = copilotModule;
              };
              shellHook = ''
                echo "🤖 AI Coding Environment (GitHub Copilot)"
                echo ""
                echo "Copilot Keymaps:"
                echo "  <M-l>       Accept suggestion"
                echo "  <M-]>/<M-[> Cycle suggestions"
                echo "  <leader>cp  Copilot panel"
                echo ""
                echo "Run :Copilot auth to authenticate"
              '';
            };

            # Codeium-based shell (free alternative)
            codeium = {
              name = "ai-codeium";
              languages = {
                python.enable = true;
                typescript.enable = true;
                nix.enable = true;
                codeium.enable = true;
              };
              extraLanguageModules = {
                codeium = codeiumModule;
              };
              shellHook = ''
                echo "🤖 AI Coding Environment (Codeium - Free)"
                echo ""
                echo "Codeium Keymaps:"
                echo "  <C-g>       Accept suggestion"
                echo "  <M-]>/<M-[> Cycle suggestions"
                echo "  <leader>cC  Codeium chat"
                echo ""
                echo "Run :Codeium Auth to authenticate"
              '';
            };

            # Full AI suite - all providers
            full = {
              name = "ai-full";
              languages = {
                python.enable = true;
                typescript.enable = true;
                nix.enable = true;
                claude.enable = true;
                copilot.enable = true;
              };
              extraLanguageModules = {
                claude = claudeModule;
                copilot = copilotModule;
              };
              extraPackages = with pkgs; [
                # Additional AI/ML tools
                python3Packages.openai
                python3Packages.anthropic
              ];
              shellHook = ''
                echo "🤖 AI Coding Environment (Full Suite)"
                echo ""
                echo "Available: Claude CLI, GitHub Copilot"
                echo "See <leader>c for Claude, <leader>cp for Copilot"
              '';
            };
          };
        };
    };
}
