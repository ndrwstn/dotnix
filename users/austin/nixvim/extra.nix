# users/austin/nixvim/extra.nix
{ pkgs }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
    luasnip # Snippet engine for blink.cmp
  ];

  extraConfigLua = builtins.readFile ./blink_wrapper.lua;
}







