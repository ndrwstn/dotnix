{
  system = "x86_64-linux";
  role = "laptop";
  features = [ "remote-builder" "cachix-push" ];
  users = [ "austin" "jessica" ];
  windowManagers = [ "gnome" "hyprland" ];
}
