# Tmux Kitty-Graphics Experimental Branch

**Branch:** `tmux-kitty-graphics`  
**Created:** March 31, 2026  
**Status:** Experimental / On Hold

---

## 1. Purpose

Enable **graphical PDF viewing inside tmux sessions** for a LaTeX/PDF workflow where the user never has to leave the terminal multiplexer.

Target workflow:

1. Edit LaTeX in nvim (inside tmux)
2. Compile document
3. View resulting PDF **without leaving tmux**
4. Continue editing

---

## 2. Custom Components

This branch uses experimental/custom software that is **not in nixpkgs**:

### 2.1 ndrwstn/tmux:dev Fork

**Repository:** `https://github.com/ndrwstn/tmux` (dev branch)  
**Base:** tmux/tmux master + merged kitty graphics branch  
**Purpose:** Adds native image handling to tmux for kitty graphics protocol

**Key additions:**

- `image-kitty.c` - kitty graphics protocol support
- `image-sixel.c` - SIXEL graphics protocol support
- `image.c` - unified image handling
- New configure flags: `--enable-kitty-images`, `--enable-sixel-images`

**How it differs from standard tmux:**

- Standard tmux with `allow-passthrough on` **forwards** graphics to the terminal
- This fork **stores** images internally and re-emits them on redraw
- Intended to survive tmux detach/reattach and pane redraws

### 2.2 termpdf.py

**Repository:** `https://github.com/dsanson/termpdf.py`  
**Purpose:** Terminal-based PDF viewer using kitty graphics protocol

**Requirement:** Terminal with kitty graphics support (Ghostty, Kitty, WezTerm)

---

## 3. Configuration Changes

### 3.1 Overlay (`overlays/tmux-kitty-graphics.nix`)

```nix
# Custom tmux derivation with graphics support
tmux = prev.tmux.overrideAttrs (oldAttrs: {
  src = fetchFromGitHub {
    owner = "ndrwstn";
    repo = "tmux";
    rev = "e555d85cb2475041c44d58e74722977aee758d54";
    # Pinned to: "Merge kitty graphics protocol support"
  };
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ autoreconfHook ];
  configureFlags = oldAttrs.configureFlags ++ [
    "--enable-kitty-images"
    "--enable-sixel-images"
  ];
});
```

### 3.2 Flake Integration (`flake.nix`)

Applied overlay globally via `sharedModules`:

```nix
nixpkgs.overlays = [ (import ./overlays/tmux-kitty-graphics.nix) ];
```

### 3.3 Tmux Configuration (`users/austin/tmux.nix`)

```nix
set -g allow-passthrough on
```

**Purpose:** Allows graphics protocol escape sequences to pass through tmux to the terminal emulator.

---

## 4. What Was Attempted & Results

| Approach                             | Configuration          | Images       | Keyboard  | Verdict                       |
| ------------------------------------ | ---------------------- | ------------ | --------- | ----------------------------- |
| **termpdf.py in Ghostty directly**   | No tmux                | ✅ Perfect   | ✅ Works  | Baseline - works perfectly    |
| **termpdf.py + custom tmux fork**    | Kitty graphics enabled | ✅ Displays  | ❌ Broken | **Main failure mode**         |
| **termpdf.py + custom fork + SIXEL** | Both flags enabled     | ✅ Displays  | ❌ Broken | No improvement                |
| **TDF viewer**                       | Text-based ratatui     | ⚠️ Illegible | ✅ Works  | Unusable for actual reading   |
| **TDF + SIXEL**                      | N/A                    | ⚠️ Illegible | ✅ Works  | Same - tdf is text-based only |

### 4.1 Failure Details: termpdf.py in Tmux

**Symptoms:**

- PDF renders and displays correctly via kitty graphics
- Cursor rapidly flickers between text select (I-beam) and pointer modes
- Zero keyboard input accepted (arrow keys, 'q', 'h/j/k/l', etc.)
- Must `ctrl-c` to terminate (SIGINT)

**Root Cause:**
Termpdf.py uses **blocking stdin reads** for kitty graphics responses:

```python
# termpdf.py ~line 1087-1096
def write_gr_cmd_with_response(cmd, payload=None):
    write_gr_cmd(cmd, payload)
    resp = b''
    while resp[-2:] != b'\033\\':  # BLOCKING READ
        resp += sys.stdin.buffer.read(1)  # Consumes keypresses!
    return resp
```

This conflicts with curses keyboard input handling. In tmux's passthrough environment, the blocking read consumes keypresses meant for the application, causing complete input failure.

**Related Issues:**

- termpdf.py GitHub Issue #49: "Not working on Ghostty+Tmux"
- kitty discussion: tmux passthrough causes "endless headaches" with graphics protocols

### 4.2 TDF Limitations

TDF (Rust-based TUI viewer) works in tmux but:

- Uses ratatui for rendering (text-based, not graphics)
- PDF pages render as illegible shapes
- Can see "form" of document but cannot read text
- Useless for actual PDF viewing

---

## 5. Technical Analysis

### 5.1 Kitty Graphics Protocol in Tmux

**Standard tmux:**

- `set -g allow-passthrough on` forwards APC sequences to terminal
- Images work but disappear on pane redraw / detach

**ndrwstn fork:**

- Stores image data internally
- Re-emits on redraw
- Survives detach/reattach
- **Does not fix input handling issues** (not a tmux problem)

### 5.2 The Real Problem

The issue is **not** in tmux configuration. It's in **termpdf.py's input handling**:

1. termpdf.py initializes curses for keyboard input
2. When displaying images, sends kitty graphics commands
3. Uses blocking `sys.stdin.buffer.read(1)` to wait for terminal response
4. In tmux passthrough, this read captures **both** graphics responses AND keypresses
5. Curses is starved of keyboard events

This would likely occur with **any** terminal + tmux combination, not Ghostty-specific.

### 5.3 Potential Fixes (Not Implemented)

**Fix termpdf.py:**

- Use `select()` for non-blocking I/O
- Read graphics responses from `/dev/tty` instead of stdin
- Detect tmux and use alternative response mechanism

**Use different terminal:**

- Test wezterm + standard tmux + termpdf.py
- If Ghostty-specific, switch terminals

**Abandon approach:**

- Use GUI PDF viewer for actual reading
- Use text-based tools (pdftotext) for quick reference

---

## 6. Future Directions

### 6.1 Immediate Options

| Option                            | Effort      | Outcome                            |
| --------------------------------- | ----------- | ---------------------------------- |
| **Patch termpdf.py**              | Medium-High | Fix input handling, use in tmux    |
| **Test wezterm**                  | Low         | Determine if Ghostty-specific      |
| **Use termpdf.py outside tmux**   | None        | Works perfectly, just not "inside" |
| **Abandon graphical PDF in tmux** | None        | External viewer or text-only       |

### 6.2 Recommended Next Steps

1. **Try wezterm + standard tmux + termpdf.py**
   - If it works → Ghostty-specific issue
   - If it fails → termpdf.py needs patching

2. **Submit bug report to termpdf.py**
   - Use the detailed analysis in this document
   - Reference the blocking stdin read issue
   - Request non-blocking I/O or `/dev/tty` separation

3. **Monitor upstream tmux**
   - tmux issue #4902: Official kitty graphics support in progress
   - `ta/kitty-img` branch may eventually provide better support

---

## 7. Cherry-Pickable Changes

The following change is **independent** and can be cherry-picked to main branches:

### `users/austin/tmux.nix`: Add `allow-passthrough on`

```diff
+      # Enable kitty graphics protocol passthrough
+      set -g allow-passthrough on
+
       # Load wallpaper-driven colors if present
```

**Commit:** `1bbc181` ("Enable kitty graphics passthrough in tmux")

This setting is **generally useful** for any graphics protocol passthrough (SIXEL, iTerm2 images, etc.) and doesn't require the custom tmux fork.

---

## 8. Files Unique to This Branch

```
overlays/tmux-kitty-graphics.nix    # Custom tmux derivation
NOTE.md                              # This file
```

**Can be safely deleted if abandoning this approach.**

---

## 9. Summary

**Goal:** Graphical PDF viewing inside tmux  
**Result:** Partially achieved - images display but input fails  
**Root cause:** termpdf.py's blocking stdin reads conflict with curses  
**Custom fork benefit:** Minimal - didn't solve the actual problem  
**Recommendation:** Either patch termpdf.py or use external to tmux

This branch serves as documentation and a testing ground for future attempts. The custom forks can be nuked unless further experimentation is desired.
