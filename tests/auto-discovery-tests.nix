# tests/auto-discovery-tests.nix
{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
  autoDiscovery = import ../lib/auto-discovery.nix { inherit lib; };
  
  # Test directory structure for discoverDirectories
  testDir = pkgs.runCommand "test-dir" {} ''
    mkdir -p $out/dir1 $out/dir2 $out/dir3
    echo '{ test = { value = 1; }; }' > $out/dir1/test.nix
    echo '{ test = { value = 2; }; }' > $out/dir2/test.nix
  '';
  
  # Test directory structure for extractSystemType
  machinesDir = pkgs.runCommand "machines-dir" {} ''
    mkdir -p $out/machine1 $out/machine2 $out/machine3 $out/machine4
    
    # Machine with _astn.machineSystem
    cat > $out/machine1/configuration.nix <<EOF
    { config, pkgs, ... }: {
      _astn.machineSystem = "x86_64-linux";
    }
    EOF
    
    # Machine with comment
    cat > $out/machine2/configuration.nix <<EOF
    # SYSTEM_TYPE: aarch64-darwin
    { config, pkgs, ... }: {
      # No _astn.machineSystem
    }
    EOF
    
    # Machine with system.nix
    cat > $out/machine3/configuration.nix <<EOF
    { config, pkgs, ... }: {
      # No system type info
    }
    EOF
    echo '"aarch64-linux"' > $out/machine3/system.nix
    
    # Machine with no system type info
    cat > $out/machine4/configuration.nix <<EOF
    { config, pkgs, ... }: {
      # No system type info
    }
    EOF
  '';
  
  # Test discoverDirectories
  discoveredDirs = autoDiscovery.discoverDirectories {
    basePath = testDir;
    filterPredicate = dir: builtins.pathExists (dir + "/test.nix");
  };
  
  expectedDirs = [ "dir1" "dir2" ];
  
  # Test extractSystemType with custom namespace
  systemType1 = autoDiscovery.extractSystemType {
    name = "machine1";
    machinesPath = machinesDir;
  };
  
  # Test extractSystemType with comment
  systemType2 = autoDiscovery.extractSystemType {
    name = "machine2";
    machinesPath = machinesDir;
  };
  
  # Test extractSystemType with system.nix
  systemType3 = autoDiscovery.extractSystemType {
    name = "machine3";
    machinesPath = machinesDir;
  };
  
  # Test extractSystemType with default
  systemType4 = autoDiscovery.extractSystemType {
    name = "machine4";
    machinesPath = machinesDir;
    defaultSystemType = "x86_64-darwin";
  };
in

pkgs.runCommand "auto-discovery-test-results" {} ''
  echo "Testing discoverDirectories..."
  if [ "${builtins.toJSON discoveredDirs}" != "${builtins.toJSON expectedDirs}" ]; then
    echo "Test failed: discoverDirectories"
    echo "Expected: ${builtins.toJSON expectedDirs}"
    echo "Got: ${builtins.toJSON discoveredDirs}"
    exit 1
  fi
  
  echo "Testing extractSystemType with custom namespace..."
  if [ "${systemType1}" != "x86_64-linux" ]; then
    echo "Test failed: extractSystemType for machine1"
    echo "Expected: x86_64-linux"
    echo "Got: ${systemType1}"
    exit 1
  fi
  
  echo "Testing extractSystemType with comment..."
  if [ "${systemType2}" != "aarch64-darwin" ]; then
    echo "Test failed: extractSystemType for machine2"
    echo "Expected: aarch64-darwin"
    echo "Got: ${systemType2}"
    exit 1
  fi
  
  echo "Testing extractSystemType with system.nix..."
  if [ "${systemType3}" != "aarch64-linux" ]; then
    echo "Test failed: extractSystemType for machine3"
    echo "Expected: aarch64-linux"
    echo "Got: ${systemType3}"
    exit 1
  fi
  
  echo "Testing extractSystemType with default..."
  if [ "${systemType4}" != "x86_64-darwin" ]; then
    echo "Test failed: extractSystemType for machine4"
    echo "Expected: x86_64-darwin"
    echo "Got: ${systemType4}"
    exit 1
  fi
  
  echo "All tests passed!" > $out
''