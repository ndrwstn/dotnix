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
]
