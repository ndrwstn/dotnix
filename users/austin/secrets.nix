# users/austin/secrets.nix
{ config, lib, pkgs, ... }:

{
  # Define the secrets
  sops.secrets = {
    # API keys
    "api_keys/github" = {
      sopsFile = ./api_keys.sops.yaml;
      key = "api_keys.github";
    };
    "api_keys/aws" = {
      sopsFile = ./api_keys.sops.yaml;
      key = "api_keys.aws";
    };
    "api_keys/gcp" = {
      sopsFile = ./api_keys.sops.yaml;
      key = "api_keys.gcp";
    };

    # SSH keys
    "ssh/github" = {
      sopsFile = ./ssh.sops.yaml;
      key = "ssh.github";
      path = "${config.home.homeDirectory}/.ssh/id_github";
      mode = "0600";
    };
    "ssh/gitlab" = {
      sopsFile = ./ssh.sops.yaml;
      key = "ssh.gitlab";
      path = "${config.home.homeDirectory}/.ssh/id_gitlab";
      mode = "0600";
    };

    # Syncthing secrets - conditionally defined based on platform
    # Note: For Darwin systems, these secrets should be defined at the system level
    # in the machine's configuration, not at the user level
  };

  # Example of using the secrets in environment variables
  home.sessionVariables = {
    GITHUB_TOKEN = "$(cat ${config.sops.secrets."api_keys/github".path})";
    AWS_ACCESS_KEY = "$(cat ${config.sops.secrets."api_keys/aws".path})";
    GCP_KEY = "$(cat ${config.sops.secrets."api_keys/gcp".path})";
  };

  # Example of using SSH keys
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        identityFile = config.sops.secrets."ssh/github".path;
        extraOptions = {
          AddKeysToAgent = "yes";
        };
      };
      "gitlab.com" = {
        identityFile = config.sops.secrets."ssh/gitlab".path;
        extraOptions = {
          AddKeysToAgent = "yes";
        };
      };
    };
  };
}
