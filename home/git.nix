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

    # Was `extraConfig`, renamed to `settings` upstream.
    settings = {
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

  # delta is its own top-level module now; it used to be `programs.git.delta`.
  programs.delta = {
    enable = true;

    # Being implicit here is deprecated - enabling delta while programs.git is
    # enabled used to wire itself up automatically and now warns.
    enableGitIntegration = true;

    options = {
      navigate = true;
      line-numbers = true;
    };
  };
}
