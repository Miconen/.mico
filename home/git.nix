{
  config,
  ...
}:
{
  programs.git = {
    enable = true;

    # Identity deliberately lives outside this repo, because this repo is
    # public. Set it once per machine:
    #   git config --file ~/.gitconfig.local user.name  "..."
    #   git config --file ~/.gitconfig.local user.email "..."
    includes = [ { path = "${config.home.homeDirectory}/.gitconfig.local"; } ];

    # Replaces the old `[core] pager` behaviour and installs the delta package.
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
      };
    };

    extraConfig = {
      core.editor = "nvim";

      init.defaultBranch = "main";

      push.autoSetupRemote = true;

      merge = {
        # Was misspelled `conflicstyle` in the old .gitconfig, so zdiff3 was
        # silently never active - git discards unknown keys without error.
        conflictstyle = "zdiff3";
        tool = "nvim";
      };

      branch.sort = "-committerdate";

      help.autocorrect = 5;

      url."git@github.com:".insteadOf = "https://github.com/";

      submodule.recurse = true;

      status.submoduleSummary = true;

      diff = {
        # Was misspelled `sudmodule` in the old .gitconfig.
        submodule = "log";
        colorMoved = "default";
        algorithm = "histogram";
      };
    };
  };
}
