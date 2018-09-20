with import <nixpkgs> {};
pkgs.runCommand "dummy" {
  buildInputs = [ python3 python3Packages.pylint python3Packages.mypy python3Packages.yapf python3Packages.ipython python3Packages.graphviz ];
} ""
