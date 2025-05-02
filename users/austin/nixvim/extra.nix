# users/austin/nixvim/extra.nix
{pkgs}: {
  extraPlugins = with pkgs.vimPlugins; [
    nvim-sops
    telescope-fzf-native-nvim
    train-nvim
    wrapping-nvim
  ];

  extraConfigLua = ''
    require('nvim_sops').setup {}
    require('telescope').load_extension('fzf')
    require('wrapping').setup {}
  '';
}
