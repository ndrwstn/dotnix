# users/austin/1password.nix
#
# Manages 1Password CLI integration for secret injection.
# Provides:
#   - Template file at ~/.config/op/secrets.tpl for `op inject`
#   - Shell init that auto-sources all API keys via a single `op` call
#
# Security model:
#   - Template contains op:// URIs only (references, not secrets) — safe in Nix store
#   - `op inject` resolves secrets in-memory — nothing written to disk
#   - Single `op` process = one biometric popup per terminal session
#   - No-op gracefully when `op` CLI is not installed
{ config, pkgs, lib, ... }:

let
  templateDir = "${config.xdg.configHome}/op";
  templateFile = "secrets.tpl";
in
{
  # Template file with op:// URIs for op inject
  # These are secure references, not secrets — safe to store in the Nix store
  xdg.configFile."op/${templateFile}".text = ''
    export BRIGHTDATA_API_TOKEN="{{ op://Private/mf2zkmjt6yw3eaoeemkgq7o4yy/API_KEY }}"
    export EXA_API_KEY="{{ op://Private/khtjwtdqcxlbj4bs7nuoqo36pa/API_KEY }}"
    # export OBSIDIAN_API_KEY="{{ op://Private/fgykqgqohmb4hflgpfkdfotk5q/API_KEY }}"
  '';

  # Source secrets via op signin + op inject — one biometric popup per token lifetime.
  # Uses op signin --raw to get a session token that works across TTYs (unlike the
  # default TTY-bound desktop app session), then op inject resolves all secrets.
  # Token is propagated to tmux's session+global env so new windows/panes inherit it.
  programs.zsh = lib.mkIf config.programs.zsh.enable {
    initContent = lib.mkAfter ''
      # ═══════════════════════════════════════════════════════════════
      # 1Password secrets injection
      # ═══════════════════════════════════════════════════════════════
      # One biometric prompt per token lifetime (~30 min). Subsequent calls use the
      # OP_SESSION_<account> token from the environment — no prompt, works across TTYs.
      if [[ -z "$_ASTN_OP_INJECTED" ]] && command -v op &>/dev/null && [[ -f "${templateDir}/${templateFile}" ]]; then
        # Get a session token (idempotent — only prompts if no valid session exists)
        eval "$(op signin 2>/dev/null)" 2>/dev/null || true

        # Inject secrets using the session token — no prompt, cross-TTY
        source <(op inject -i "${templateDir}/${templateFile}" 2>/dev/null)
        export _ASTN_OP_INJECTED=1

        # Propagate to tmux session env so new windows/panes inherit
        if [[ -n "$TMUX" ]] && command -v tmux &>/dev/null; then
          tmux set-environment -s _ASTN_OP_INJECTED 1 2>/dev/null || true
          [[ -n "$BRIGHTDATA_API_TOKEN" ]] && tmux set-environment -s BRIGHTDATA_API_TOKEN "$BRIGHTDATA_API_TOKEN" 2>/dev/null || true
          [[ -n "$EXA_API_KEY" ]] && tmux set-environment -s EXA_API_KEY "$EXA_API_KEY" 2>/dev/null || true
          # Also propagate any OP_SESSION_* tokens so new panes inherit auth
          for _var in $(env | sed -n 's/^\(OP_SESSION_[^=]*\)=.*/\1/p'); do
            tmux set-environment -s "$_var" "''${(P)_var}" 2>/dev/null || true
            tmux set-environment -g "$_var" "''${(P)_var}" 2>/dev/null || true
          done
        fi
      fi
    '';
  };
}
