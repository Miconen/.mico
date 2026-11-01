{
  config,
  ...
}:
{
  programs.git = {
    enable = true;

    # Identity lives outside this public repo, in ~/.gitconfig.local.
    includes = [ { path = "${config.home.homeDirectory}/.gitconfig.local"; } ];

    settings = {
      core.editor = "nvim";

      init.defaultBranch = "main";

      push.autoSetupRemote = true;

      merge = {
        conflictstyle = "zdiff3";
        tool = "nvim";
      };

      branch.sort = "-committerdate";

      rerere = {
        enabled = true;
        autoUpdate = true;
      };

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      fetch = {
        prune = true;
        pruneTags = true;
      };

      commit.verbose = true;

      push.followTags = true;

      diff.mnemonicPrefix = true;

      column.ui = "auto";

      help.autocorrect = 5;

      url."git@github.com:".insteadOf = "https://github.com/";

      submodule.recurse = true;

      status.submoduleSummary = true;

      diff = {
        submodule = "log";
        colorMoved = "default";
        algorithm = "histogram";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      navigate = true;
      line-numbers = true;
    };
  };
}
