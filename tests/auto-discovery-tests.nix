# tests/auto-discovery-tests.nix
{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
  autoDiscovery = import ../lib/auto-discovery.nix { inherit lib; };
  
  # Test directory structure
  testDir = pkgs.runCommand "test-dir" {} ''
    mkdir -p $out/dir1 $out/dir2 $out/dir3
    echo '{ test = { value = 1; }; }' > $out/dir1/test.nix
    echo '{ test = { value = 2; }; }' > $out/dir2/test.nix
  '';
  
  # Test discoverDirectories
  discoveredDirs = autoDiscovery.discoverDirectories {
    basePath = testDir;
    filterPredicate = dir: builtins.pathExists (dir + "/test.nix");
  };
  
  expectedDirs = [ "dir1" "dir2" ];
in

pkgs.runCommand "auto-discovery-test-results" {} ''
  echo "Testing discoverDirectories..."
  if [ "${builtins.toJSON discoveredDirs}" != "${builtins.toJSON expectedDirs}" ]; then
    echo "Test failed: discoverDirectories"
    echo "Expected: ${builtins.toJSON expectedDirs}"
    echo "Got: ${builtins.toJSON discoveredDirs}"
    exit 1
  fi
  
  echo "All tests passed!" > $out
''