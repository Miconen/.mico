{
  lib,
  config,
  repoPath,
  ...
}:
let
  skillsDir = ../config/claude/skills;
  skills = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );
in
{
  # Claude Code skills, one symlink per skill. Drop a folder with a SKILL.md into
  # config/claude/skills and it is picked up on the next switch.
  #
  # Each skill is linked individually rather than owning ~/.claude/skills as a
  # whole: Claude Code writes its own synced skills into that directory, and
  # unmanaged local skills can live alongside these.
  #
  # mkOutOfStoreSymlink points at the working tree rather than the nix store, so
  # editing a skill (by hand or via Claude) takes effect immediately and shows up
  # in `git status` here, instead of hitting a read-only store path.
  home.file = lib.listToAttrs (
    map (name: {
      name = ".claude/skills/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/config/claude/skills/${name}";
    }) skills
  );
}
