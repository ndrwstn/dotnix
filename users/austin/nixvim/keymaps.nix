# users/austin/nixvim/keymaps.nix
{
  keymaps = [
    # Neotree
    {
      key = "<leader>ef";
      mode = "n";
      action = "<cmd>Neotree action=focus source=filesystem position=left<CR>";
      options = {
        silent = true;
        desc = "Show Filesystem in Neotree";
      };
    }
    {
      key = "<leader>ex";
      mode = "n";
      action = "<cmd>Neotree action=close source=filesystem position=left<CR>";
      options = {
        silent = true;
        desc = "Close Neotree Filesystem";
      };
    }
    {
      key = "<leader>er";
      mode = "n";
      action = "<cmd>Neotree action=focus source=filesystem reveal=true position=left<CR>";
      options = {
        silent = true;
        desc = "Show Current File in Neotree";
      };
    }
    # sops-nvim
    {
      key = "<leader>usd";
      mode = "n";
      action = "<cmd>SopsDecrypt<CR>";
      options = {
        silent = true;
        desc = "Decrypt File with Sops";
      };
    }
    {
      key = "<leader>use";
      mode = "n";
      action = "<cmd>SopsEncrypt<CR>";
      options = {
        silent = true;
        desc = "Encrypt File with Sops";
      };
    }
  ];
}
