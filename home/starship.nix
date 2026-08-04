{
  ...
}:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    # Replaces powerlevel10k (which was a git submodule plus a generated
    # ~/.p10k.zsh). The preset ships inside the starship package at
    # $out/share/starship/presets/ and already defaults to the Mocha palette,
    # so no palette override is needed here.
    #
    # Requires a Nerd Font for the powerline separators - see maple-mono.NF in
    # common.nix and set it as your kitty font.
    presets = [ "catppuccin-powerline" ];

    # `settings` is deep-merged on top of the presets, so anything added here
    # wins over the preset.
    settings = {
      add_newline = false;
    };
  };
}
