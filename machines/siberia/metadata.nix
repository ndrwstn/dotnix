{
  system = "x86_64-linux";
  role = "desktop";
  features = [ "remote-builder" "cachix-push" ];
  users = [ "austin" "jessica" ];
  windowManagers = [ "hyprland" "i3" ];
}
