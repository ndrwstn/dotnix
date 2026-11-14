{
  system = "x86_64-linux";
  role = "laptop";
  features = [ "cachix-push" ];
  users = [ "austin" ];
  windowManagers = [ "i3" ];
}
