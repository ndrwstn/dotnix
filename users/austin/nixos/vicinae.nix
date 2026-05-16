# users/austin/nixos/vicinae.nix
# Vicinae launcher configuration (Raycast-like for Linux)
{ ... }: {
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      environment = {
        TMUX_TMPDIR = "%t";
        XDG_RUNTIME_DIR = "%t";
      };
    };
  };
}
