{
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
        python = "3.14";
        go = "1.26";
        rust = "1.97";
      };
    };
  };
}
