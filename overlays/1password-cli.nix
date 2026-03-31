final: prev:

{
  _1password-cli = prev._1password-cli.overrideAttrs (oldAttrs: {
    nativeBuildInputs = builtins.filter (input: input != prev.autoPatchelfHook) oldAttrs.nativeBuildInputs;
    dontAutoPatchelf = true;

    postFixup = (oldAttrs.postFixup or "") + ''
      mkdir -p "$out/libexec"
      mv "$out/bin/op" "$out/libexec/op-real"

            cat > "$TMPDIR/op-launcher.c" <<'EOF'
      #include <errno.h>
      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>
      #include <sys/stat.h>
      #include <sys/types.h>
      #include <unistd.h>

      extern char **environ;

      static const char *wrapper_path = "/run/wrappers/bin/op";
      static const char *real_path = "${placeholder "out"}/libexec/op-real";
      static const char *guard_env = "OP_NIX_WRAPPER_REEXEC";

      static void die_errno(const char *message) {
        fprintf(stderr, "op launcher: %s: %s\n", message, strerror(errno));
        exit(126);
      }

      static void die_message(const char *message) {
        fprintf(stderr, "op launcher: %s\n", message);
        exit(126);
      }

      int main(int argc, char *argv[]) {
        struct stat st;
        gid_t current_gid = getegid();
        int have_wrapper = stat(wrapper_path, &st) == 0;

        if (have_wrapper) {
          gid_t wrapper_gid = st.st_gid;
          const char *reexeced = getenv(guard_env);

          if (current_gid != wrapper_gid) {
            if (reexeced != NULL && reexeced[0] != '\0') {
              fprintf(
                stderr,
                "op launcher: wrapper re-exec did not acquire expected gid (current=%lu expected=%lu)\n",
                (unsigned long)current_gid,
                (unsigned long)wrapper_gid
              );
              return 126;
            }

            if (setenv(guard_env, "1", 1) != 0) {
              die_errno("failed to set OP_NIX_WRAPPER_REEXEC");
            }

            execve(wrapper_path, argv, environ);
            die_errno("failed to exec wrapper");
          }
        } else if (errno != ENOENT) {
          die_errno("failed to stat wrapper");
        }

        execve(real_path, argv, environ);

        if (errno == ENOENT) {
          die_message("real 1Password CLI binary not found");
        }

        die_errno("failed to exec real 1Password CLI binary");
      }
      EOF

            ${prev.stdenv.cc.targetPrefix}cc \
              -O2 \
              -Wall \
              -Wextra \
              -o "$out/bin/op" \
              "$TMPDIR/op-launcher.c"

            chmod 0555 "$out/bin/op"
    '';
  });
}
