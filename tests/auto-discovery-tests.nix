# tests/auto-discovery-tests.nix
{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
  autoDiscovery = import ../lib/auto-discovery.nix { inherit lib; };
  
  # Test directory structure
  testDir = pkgs.runCommand "test-dir" {} ''
    mkdir -p $out/dir1 $out/dir2 $out/dir3
    touch $out/dir1/test.nix
    echo '{ test = { value = 1; }; }' > $out/dir1/test.nix
    echo '{ test = { value = 2; }; }' > $out/dir2/test.nix
  '';
  
  # Test discoverDirectories
  discoveredDirs = autoDiscovery.discoverDirectories {
    basePath = testDir;
    filterPredicate = dir: builtins.pathExists (dir + "/test.nix");
  };
  
  expectedDirs = [ "dir1" "dir2" ];
  
  # Test discoverAndMergeConfigs
  mergedConfig = autoDiscovery.discoverAndMergeConfigs {
    directories = [ "${testDir}/dir1" "${testDir}/dir2" "${testDir}/dir3" ];
    filePath = "test.nix";
    attributeName = "test";
  };
  
  expectedConfig = { value = 2; }; # Last one wins in mkMerge
in

pkgs.runCommand "auto-discovery-test-results" {} ''
  echo "Testing discoverDirectories..."
  if [ "${builtins.toJSON discoveredDirs}" != "${builtins.toJSON expectedDirs}" ]; then
    echo "Test failed: discoverDirectories"
    echo "Expected: ${builtins.toJSON expectedDirs}"
    echo "Got: ${builtins.toJSON discoveredDirs}"
    exit 1
  fi
  
  echo "Testing discoverAndMergeConfigs..."
  if [ "${builtins.toJSON mergedConfig}" != "${builtins.toJSON expectedConfig}" ]; then
    echo "Test failed: discoverAndMergeConfigs"
    echo "Expected: ${builtins.toJSON expectedConfig}"
    echo "Got: ${builtins.toJSON mergedConfig}"
    exit 1
  fi
  
  echo "All tests passed!" > $out
''