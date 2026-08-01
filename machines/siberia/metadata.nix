{
  system = "x86_64-linux";
  role = "desktop";
  features = [ "remote-builder" ];
  users = [ "austin" "jessica" ];
  windowManagers = [ "hyprland" "i3" ];
}
