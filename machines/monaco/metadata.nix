{
  system = "aarch64-darwin";
  role = "desktop";
  features = [ "llm" "clamav" "remote-builder" ];
  users = [ "austin" "jessica" ];
  windowManagers = [ ];
}
