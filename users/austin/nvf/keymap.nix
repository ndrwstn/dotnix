# users/austin/nvf/keymap.nix
{...}: [
  # Neotree
  {
    key = "<leader>ef";
    mode = "n";
    silent = true;
    action = "<cmd>Neotree action=focus source=filesystem position=left<CR>";
    desc = "Show Filesystem in Neotree";
  }
  {
    key = "<leader>ex";
    mode = "n";
    silent = true;
    action = "<cmd>Neotree action=close source=filesystem position=left<CR>";
    desc = "Close Neotree Filesystem";
  }
  {
    key = "<leader>er";
    mode = "n";
    silent = true;
    action = "<cmd>Neotree action=focus source=filesystem reveal=true position=left<CR>";
    desc = "Show Current File in Neotree";
  }
  # sops-nvim
  {
    key = "<leader>usd";
    mode = "n";
    silent = true;
    action = "<cmd>SopsDecrypt";
    desc = "Decrypt File with Sops";
  }
  {
    key = "<leader>use";
    mode = "n";
    silent = true;
    action = "<cmd>SopsEncrypt";
    desc = "Encrypt File with Sops";
  }
]
