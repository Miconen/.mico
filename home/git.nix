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

      # Remember how a conflict was resolved and replay it next time the same
      # conflict shows up. The single biggest quality-of-life win for rebases.
      rerere = {
        enabled = true;
        autoUpdate = true;
      };

      rebase = {
        # No more "cannot rebase: you have unstaged changes".
        autoStash = true;
        # Honour `fixup!`/`squash!` commits without passing -i --autosquash.
        autoSquash = true;
        # Rewrite other local branches that pointed into the rebased range,
        # which is what makes stacked branches survive a rebase.
        updateRefs = true;
      };

      fetch = {
        # Delete local refs for branches and tags deleted upstream, instead of
        # accumulating them forever.
        prune = true;
        pruneTags = true;
      };

      # Show the staged diff in the commit message editor.
      commit.verbose = true;

      # Push annotated tags along with the commits that reference them.
      push.followTags = true;

      # a/ b/ prefixes become c/ w/ i/ o/ (commit, working tree, index, object),
      # so it is clear what is being compared.
      diff.mnemonicPrefix = true;

      # Columnar output for `git branch`, `git tag`, etc.
      column.ui = "auto";

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
