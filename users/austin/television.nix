# users/austin/television.nix - Television (tv) configuration
#
# Provides:
#   - The television package itself (moved from default.nix)
#   - Tab completion for the `tv` command with channel-name completion
#   - Ctrl+G smart autocomplete (context-aware channel triggers)
#   - Does NOT override atuin (Ctrl+R) or fzf (Ctrl+T)
{ config, pkgs, lib, autopkgs, ... }:
let
  tvPkg = autopkgs.television;
  configDir = "${config.xdg.configHome}/television";
in
{
  # Install television package
  home.packages = [ tvPkg ];

  # Shell integration for zsh
  programs.zsh = lib.mkIf config.programs.zsh.enable {
    initContent = lib.mkAfter ''
      # ═══════════════════════════════════════════════════════════════
      # television (tv) integration
      # ═══════════════════════════════════════════════════════════════

      # ── Tab completion (with channel names) ──────────────────────
      # Generate lazily on first shell login so it uses the correct
      # tv version and keybindings can be patched without build-time
      # cross-platform issues.
      _TV_COMPLETION="${configDir}/completion.zsh"
      if [[ ! -f "$_TV_COMPLETION" ]] && command -v tv &>/dev/null; then
        mkdir -p "${configDir}" 2>/dev/null
        tv completions zsh 2>/dev/null > "$_TV_COMPLETION.tmp" && {
          # Replace _default completer with _tv_channels for the
          # channel positional argument, enabling channel-name completion
          sed '/::channel/s/_default/_tv_channels/' "$_TV_COMPLETION.tmp" > "$_TV_COMPLETION" 2>/dev/null
          rm -f "$_TV_COMPLETION.tmp"
        }
      fi
      [[ -f "$_TV_COMPLETION" ]] && source "$_TV_COMPLETION"
      unset _TV_COMPLETION

      # Custom channel-name completion function
      # Called by the modified _tv completer when completing the
      # channel positional argument
      _tv_channels() {
        local -a channels
        channels=(''${(f)"$(tv list-channels 2>/dev/null)"})
        _describe 'channel' channels
      }

      # ── Smart autocomplete (Ctrl+G) ─────────────────────────────
      # Press Ctrl+G while typing a command to open tv with a
      # context-appropriate channel:
      #   cd <Ctrl+G>  → dirs channel
      #   git co <Ctrl+G> → git-branch channel
      #   nvim <Ctrl+G> → git-repos channel
      #   kubectl <Ctrl+G> → k8s-pods channel
      #   (default)      → files channel
      #
      # This does NOT override atuin's Ctrl+R (history search) or
      # fzf's Ctrl+T (fuzzy path completion).

      _disable_bracketed_paste() {
        if [[ -n $zle_bracketed_paste ]]; then
          print -nr $zle_bracketed_paste[2] >''${TTY:-/dev/tty}
        fi
      }

      _enable_bracketed_paste() {
        if [[ -n $zle_bracketed_paste ]]; then
          print -nr $zle_bracketed_paste[1] >''${TTY:-/dev/tty}
        fi
      }

      __tv_path_completion() {
        local base lbuf suffix tail dir leftover matches
        base=$1
        lbuf=$2
        suffix=""
        tail=" "

        eval "base=$base" 2>/dev/null || return
        [[ $base = *"/"* ]] && dir="$base"
        while [ 1 ]; do
          if [[ -z "$dir" || -d $dir ]]; then
            leftover=''${base/#"$dir"}
            leftover=''${leftover/#\/}
            [ -z "$dir" ] && dir='.'
            [ "$dir" != "/" ] && dir="''${dir/%\//}"
            zle -I
            matches=$(
              shift
              tv "$dir" --autocomplete-prompt "$lbuf" --inline --no-status-bar --input "$leftover" < /dev/tty | while read -r item; do
                item="''${item%$suffix}$suffix"
                dirP="$dir/"
                [[ $dirP = "./" ]] && dirP=""
                echo -n -E "$dirP''${(q)item} "
              done
            )
            matches=''${matches% }
            if [ -n "$matches" ]; then
              LBUFFER="$lbuf$matches$tail"
            fi
            zle reset-prompt
            break
          fi
          dir=$(dirname "$dir")
          dir=''${dir%/}/
        done
      }

      _tv_smart_autocomplete() {
        _disable_bracketed_paste

        local tokens prefix lbuf
        setopt localoptions noshwordsplit noksh_arrays noposixbuiltins

        tokens=(''${(z)LBUFFER})
        if [ ''${#tokens} -lt 1 ]; then
          zle ''${fzf_default_completion:-expand-or-complete}
          return
        fi

        [[ ''${LBUFFER[-1]} == ' ' ]] && tokens+=("")

        if [[ ''${LBUFFER} = *"''${tokens[-2]-}''${tokens[-1]}" ]]; then
          tokens[-2]="''${tokens[-2]-}''${tokens[-1]}"
          tokens=(''${tokens[0,-2]})
        fi

        lbuf=$LBUFFER
        prefix=''${tokens[-1]}
        [ -n "''${tokens[-1]}" ] && lbuf=''${lbuf:0:-''${#tokens[-1]}}

        __tv_path_completion "$prefix" "$lbuf"

        _enable_bracketed_paste
      }

      zle -N tv-smart-autocomplete _tv_smart_autocomplete
      bindkey '^G' tv-smart-autocomplete
    '';
  };
}
