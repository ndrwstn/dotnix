# users/austin/nixvim/keymaps.nix
{
  keymaps = [
    # Buffer Navigation
    { key = "<leader>bn"; mode = "n"; action = "<cmd>bnext<CR>"; options.desc = "Next Buffer"; }
    { key = "<leader>bp"; mode = "n"; action = "<cmd>bprevious<CR>"; options.desc = "Previous Buffer"; }
    { key = "<leader>bd"; mode = "n"; action = "<cmd>bdelete<CR>"; options.desc = "Delete Buffer"; }

    # Neotree
    { key = "<leader>ef"; mode = "n"; action = "<cmd>Neotree action=focus source=filesystem position=left<CR>"; options.desc = "Show Files (Neotree)"; }
    { key = "<leader>ex"; mode = "n"; action = "<cmd>Neotree action=close source=filesystem position=left<CR>"; options.desc = "Close Files (Neotree)"; }
    { key = "<leader>er"; mode = "n"; action = "<cmd>Neotree action=focus source=filesystem reveal=true position=left<CR>"; options.desc = "Reveal File (Neotree)"; }

    # sops-nvim
    { key = "<leader>usd"; mode = "n"; action = "<cmd>SopsDecrypt<CR>"; options.desc = "Decrypt File (Sops)"; }
    { key = "<leader>use"; mode = "n"; action = "<cmd>SopsEncrypt<CR>"; options.desc = "Encrypt File (Sops)"; }

    # Telescope
    { key = "<leader>ff"; mode = "n"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Find Files (Telescope)"; }
    { key = "<leader>fg"; mode = "n"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Find Grep (Telescope)"; }
    { key = "<leader>fb"; mode = "n"; action = "<cmd>Telescope buffers<CR>"; options.desc = "Find Buffers (Telescope)"; }
    { key = "<leader>fh"; mode = "n"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Find Help (Telescope)"; }
    { key = "<leader>fp"; mode = "n"; action = "<cmd>Telescope projects<CR>"; options.desc = "Find Projects (Telescope)"; }
  ];
}
