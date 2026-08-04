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
    globalConfig = {
      tools = {
        node = "lts";
        python = "latest";
        go = "latest";
        rust = "latest";
      };
    };
  };
}
