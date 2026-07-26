# machines/_opencode/secrets.nix
# VM-specific agenix secrets configuration for the opencode template.
{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;

  # Age identity key — injected at VMA build time via OPCODE_TEMPLATE_KEY
  # environment variable. The key content is piped directly from:
  #   age -d -i ~/.ssh/id_ed25519 secrets/templates/opencode.age
  # No key material ever touches a file on disk or git.
  # Build with:  ./bin/build-opencode-vma
  templateKeyContent = builtins.getEnv "OPCODE_TEMPLATE_KEY";
in
{
  # The age identity key is conditionally defined only when building
  # the VMA image (OPCODE_TEMPLATE_KEY env var is set). During normal
  # flake checks or evaluation, the key is not available and the
  # identity path is empty (no agenix decryption possible).
  environment.etc."age/identity.key" = mkIf (templateKeyContent != "") {
    source = pkgs.writeText "opencode-age-identity" templateKeyContent;
    mode = "0400";
    group = "root";
  };

  # Agenix identity — points at the identity key when available.
  # conditionally set so flake check passes without the env var.
  age.identityPaths = mkIf (templateKeyContent != "") [
    "/etc/age/identity.key"
  ];

  # VM-specific agenix secrets
  # Note: general and atuin are defined in systems/common/secrets.nix
  # (shared across all machines) — only machine-specific secrets here.
  # Note: Gitea/GitHub keys are template-specific, separate from the main
  # flake keys, so a template clone compromise doesn't expose shared keys.
  age.secrets = {
    # Gitea SSH key — separate from main flake, for template clones only
    key-gitea = {
      file = ../../secrets/ssh/key-gitea-opencode.age;
      path = "/home/austin/.ssh/id_gitea";
      mode = "0600";
      owner = "austin";
      group = "projects";
    };

    # GitHub SSH key — separate from main flake, for template clones only
    key-github = {
      file = ../../secrets/ssh/key-github-opencode.age;
      path = "/home/austin/.ssh/id_github";
      mode = "0600";
      owner = "austin";
      group = "projects";
    };

    # opencode serve password environment file
    opencode-serve-env = {
      file = ../../secrets/opencode-serve-password.age;
      mode = "0400";
      owner = "opencode";
      group = "opencode";
    };
  };
}
