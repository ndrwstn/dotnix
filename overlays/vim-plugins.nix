# Work around a stale fixed-output hash in the stable nixpkgs vim plugin set.
# copilot.lua v2.0.4 contains bundled JavaScript whose GitHub archive hash is
# different from the hash currently recorded by nixpkgs.
final: prev:

{
  vimPlugins = prev.vimPlugins // {
    copilot-lua = prev.vimPlugins.copilot-lua.overrideAttrs (old: {
      src = old.src.overrideAttrs (_: {
        outputHash = "sha256-05f76OeWBlFmlUh90tH4XMMKfNI1jnhuIJDqYPPQokA=";
      });
    });
  };
}
