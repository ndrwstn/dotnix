# users/austin/nixvim/extra.nix
{ pkgs, unstable }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
    luasnip # Snippet engine for blink.cmp
  ];

  extraConfigLua = '''';
}







