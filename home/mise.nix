{
  pkgs,
  lib,
  ...
}:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    # Single source of truth for language runtimes. This replaces:
    #   - nvm, which the old config sourced TWICE ($NVM_DIR and
    #     /usr/share/nvm), competing with mise for PATH
    #   - rustup via ~/.cargo/env
    #   - `export PATH=$PATH:$(go env GOPATH)/bin`, which spawned a go
    #     subprocess on every shell start
    #
    # Per-project versions still win: drop a mise.toml or .tool-versions in a
    # repo and it overrides these globals.
    #
    # Pinned to major/minor rather than "lts"/"latest" on purpose. Those float
    # and resolve at install time, so a machine set up later would land on
    # different majors - which defeats the point of pinning nixpkgs with
    # flake.lock. Patch releases still flow in automatically.
    #
    # To upgrade: bump the value here, then `mise install`.
    globalConfig = {
      tools = {
        node = "24";
        # Pin the patch: on the WSL install, mise's cached remote-version lookup
        # passed the fuzzy "3.13" selector directly to python-build. That tool
        # only has concrete definitions (3.13.15), so fallback compilation died
        # with "definition not found: 3.13".
        python = "3.13.15";
        go = "1.26";
        rust = "1.97";
      };
    };
  };

  # Declaring a tool does not fetch it - `mise ls` would show "(missing)" until
  # someone remembers to run `mise install`. This makes the fetch part of
  # activation, so `hms` alone is sufficient and there is no manual step.
  #
  # Runs after writeBoundary so ~/.config/mise/config.toml is already in place.
  # It is a fast no-op once everything is installed, and deliberately non-fatal:
  # activating while offline should warn, not fail the whole generation.
  #
  # Set MICO_SKIP_MISE_INSTALL=1 to skip (useful on a metered connection).
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -n "''${MICO_SKIP_MISE_INSTALL:-}" ]; then
      verboseEcho "Skipping mise install (MICO_SKIP_MISE_INSTALL is set)"
    elif ! (
      export MISE_YES=1
      export PATH="${lib.makeBinPath [ pkgs.curl pkgs.wget pkgs.openssh pkgs.git ]}:$PATH"
      run --quiet ${pkgs.mise}/bin/mise install
    ); then
      warnEcho "mise install failed - offline? Run 'mise install' when connected."
    fi
  '';
}
