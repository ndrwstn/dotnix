# users/austin/darwin/java-home.nix
#
# Registers the nix-provided Zulu JDK 21 with macOS's JavaVM discovery
# system. Nix store JDKs are invisible to `/usr/libexec/java_home` by
# default, which is how GUI tools (IntelliJ, Android Studio, ...) and
# `java_home` itself locate installed JVMs.
#
# Apple's discovery mechanism also scans the per-user JVM directory
# (~/Library/Java/JavaVirtualMachines), so symlinking the .jdk bundle there
# registers it with macOS without touching /Library or requiring sudo.
#
# The symlink source uses the nixpkgs passthru attribute
# `<jdk>.bundle` (<store>/Library/Java/JavaVirtualMachines/zulu-21.jdk) so
# the link tracks the correct store path automatically across updates.
{ config
, pkgs
, lib
, ...
}:

lib.mkIf pkgs.stdenv.isDarwin {
  home.file."Library/Java/JavaVirtualMachines/zulu-21.jdk".source =
    "${pkgs.jdk21.passthru.bundle}";

  # CLI convenience: the package root carries a POSIX-style bin/java layout,
  # making it a valid JAVA_HOME for command-line tooling.
  home.sessionVariables.JAVA_HOME = "${pkgs.jdk21.home}";
}
