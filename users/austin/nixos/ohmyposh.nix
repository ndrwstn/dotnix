{ config, ... }:
{
  xdg.configFile."oh-my-posh/ohmyposh-default.json".source =
    ../shell/ohmyposh-default.json;

  programs.oh-my-posh.configFile =
    "${config.xdg.configHome}/oh-my-posh/wallpaper.json";
}
