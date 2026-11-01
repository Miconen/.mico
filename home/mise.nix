{
  pkgs,
  lib,
  ...
}:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    # Pinned to major/minor rather than "lts"/"latest" so new machines match.
    # A project's mise.toml / .tool-versions overrides these.
    globalConfig = {
      tools = {
        node = "24";
        # Full patch: python-build has no definition for a fuzzy "3.13".
        python = "3.13.15";
        go = "1.26";
        rust = "1.97";
      };
      # Auto-activate a project's uv-created .venv on cd.
      settings.python.uv_venv_auto = true;
    };
  };

  # Fetch declared tools on activation. Non-fatal so offline switches still work;
  # set MICO_SKIP_MISE_INSTALL=1 to skip.
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -n "''${MICO_SKIP_MISE_INSTALL:-}" ]; then
      verboseEcho "Skipping mise install (MICO_SKIP_MISE_INSTALL is set)"
    elif ! (
      export MISE_YES=1
      export PATH="${
        lib.makeBinPath [
          pkgs.curl
          pkgs.wget
          pkgs.openssh
          pkgs.git
        ]
      }:$PATH"
      run --quiet ${pkgs.mise}/bin/mise install
    ); then
      warnEcho "mise install failed - offline? Run 'mise install' when connected."
    fi
  '';
}
