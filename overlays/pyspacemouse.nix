# overlays/pyspacemouse.nix
#
# Darwin-only overlay: packages easyhid-ng and pyspacemouse for Python 3.11,
# which is the Python version bundled by FreeCAD.app (Homebrew cask).
#
# easyhid-ng is patched to embed the absolute Nix store path to
# libhidapi.dylib, eliminating the need for DYLD_LIBRARY_PATH at runtime
# (which SIP would strip anyway for Hardened Runtime binaries like FreeCAD.app).
#
# This overlay is NOT added to overlays/default.nix (which is Linux-only).
# It is applied in systems/darwin/default.nix instead.
final: prev:

# Guard: this overlay is Darwin-only (the .dylib path in easyhid-ng's postPatch
# would break on Linux, and spacemouse support is only needed for FreeCAD.app).
if prev.stdenv.isDarwin then
  let
    pyspacemouseOverlay = self: super: {
      easyhid-ng = super.buildPythonPackage rec {
        pname = "easyhid-ng";
        version = "0.1.0";
        format = "pyproject";

        src = prev.fetchurl {
          url = "https://files.pythonhosted.org/packages/e1/e3/6cbdea8c8869c53ee6ae95456f0e2bfc24c24bdff1be63e22febc780aa21/easyhid_ng-${version}.tar.gz";
          sha256 = "0ngrdshap8pbcgglxdmn301b689ad3az23kfb80wvbhhrzz13v1k";
        };

        nativeBuildInputs = [ super.hatchling ];
        propagatedBuildInputs = [ super.cffi ];

        # Patch easyhid-ng to embed the absolute Nix store path to hidapi's
        # shared library. This avoids needing DYLD_LIBRARY_PATH at runtime
        # since cffi's dlopen() will use this exact path.
        postPatch = ''
          substituteInPlace easyhid/easyhid.py \
            --replace 'ffi.dlopen("hidapi")' \
                      'ffi.dlopen("${prev.hidapi}/lib/libhidapi.dylib")'
        '';

        doCheck = false;
        pythonImportsCheck = [ "easyhid" ];

        meta = with prev.lib; {
          description = "Simple interface to the HIDAPI library";
          homepage = "https://github.com/JakubAndrysek/python-easyhid-ng";
          license = licenses.mit;
          maintainers = [ ];
        };
      };

      pyspacemouse = super.buildPythonPackage rec {
        pname = "pyspacemouse";
        version = "2.0.0";
        format = "pyproject";

        src = super.fetchPypi {
          inherit pname version;
          sha256 = "03rn3vdhf5whrgiabp88nnrw51ig7m4rgyzk9zv23ij883bmw0nz";
        };

        nativeBuildInputs = [ super.hatchling super."hatch-vcs" ];
        propagatedBuildInputs = [ self.easyhid-ng ];

        doCheck = false;
        pythonImportsCheck = [ "pyspacemouse" ];

        meta = with prev.lib; {
          description = "Multiplatform Python library for 3Dconnexion SpaceMouse devices using raw HID";
          homepage = "https://github.com/JakubAndrysek/pyspacemouse";
          license = licenses.mit;
          maintainers = [ ];
        };
      };
    };
  in
  {
    python311Packages = prev.python311Packages.overrideScope pyspacemouseOverlay;
  }
else
  { }
