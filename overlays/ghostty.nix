final: prev:

if prev ? ghostty then
  {
    ghostty = prev.ghostty.overrideAttrs (oldAttrs: {
      nativeBuildInputs = builtins.filter (input: input != prev.wrapGAppsHook4) oldAttrs.nativeBuildInputs;
      dontWrapGApps = true;

      postFixup = prev.lib.replaceStrings
        [ "$out/bin/.ghostty-wrapped" ]
        [ "$out/bin/ghostty" ]
        oldAttrs.postFixup;
    });
  }
else
  { }
