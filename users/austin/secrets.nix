# users/austin/secrets.nix
{ config, lib, pkgs, ... }:

{
  # Define the secrets
  sops.secrets = {
    # API keys
    "api_keys/github" = {
      sopsFile = ../../secrets/users/austin/api_keys.yaml;
      key = "api_keys.github";
    };
    "api_keys/aws" = {
      sopsFile = ../../secrets/users/austin/api_keys.yaml;
      key = "api_keys.aws";
    };
    "api_keys/gcp" = {
      sopsFile = ../../secrets/users/austin/api_keys.yaml;
      key = "api_keys.gcp";
    };
  };

  # Example of using the secrets in environment variables
  home.sessionVariables = {
    GITHUB_TOKEN = "$(cat ${config.sops.secrets."api_keys/github".path})";
    AWS_ACCESS_KEY = "$(cat ${config.sops.secrets."api_keys/aws".path})";
    GCP_KEY = "$(cat ${config.sops.secrets."api_keys/gcp".path})";
  };
}