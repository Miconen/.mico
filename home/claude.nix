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
  # One symlink per skill rather than owning ~/.claude/skills, since Claude Code
  # writes its own skills there. Out-of-store so edits land in the working tree.
  home.file = lib.listToAttrs (
    map (name: {
      name = ".claude/skills/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/config/claude/skills/${name}";
    }) skills
  );
}
