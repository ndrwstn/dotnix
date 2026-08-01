{
  system = "x86_64-linux";
  role = "laptop";
  features = [ "remote-builder" ];
  users = [ "austin" "jessica" ];
  windowManagers = [ "gnome" "hyprland" ];
}
