# users/austin/git.nix
{ config, pkgs, lib, ... }:
{
  # Delta — standalone config with git integration
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Andrew Austin";
        email = "austin@impetuo.us";
      };

      # Silence git init hint
      init.defaultBranch = "master";

      # Performance & protocol
      protocol.version = 2;
      core = {
        untrackedCache = true;
        commitGraph = true;
        fsmonitor = true;
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
      };
      gc.writeCommitGraph = true;
      fetch.writeCommitGraph = true;

      # Integrity — verify objects on transfer
      transfer.fsckObjects = true;
      fetch.fsckObjects = true;
      receive.fsckObjects = true;

      # Pull / merge behavior
      pull.ff = "only";
      merge.conflictStyle = "zdiff3";

      # Diff settings
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        context = 5;
        mnemonicPrefix = true;
      };

      # Fetch — keep remote refs clean
      fetch = {
        prune = true;
        pruneTags = true;
      };

      # Push — eliminate upstream friction
      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      # Rebase workflow helpers
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };

      # Rerere — remember resolved conflicts
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      # Log / listing preferences
      commit.verbose = true;
      branch.sort = "-committerdate";
      column.ui = "auto";
      log.date = "iso";

      # Usability
      help.autocorrect = "prompt";
      blame.ignoreRevsFile = ".git-blame-ignore-revs";

      # URL rewriting — auto-convert HTTPS GitHub URLs to SSH
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
}
