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

      cmd_duration = {
        # The catppuccin-powerline preset turns this on with a 45s threshold,
        # which fires a desktop notification every time you close nvim, a long
        # ssh session, or anything else interactive. Off.
        show_notifications = false;

        # Inline "in 1m20s" in the prompt is kept - it's useful. starship has no
        # per-command ignore list, so if you want it gone for interactive apps
        # too, either raise min_time well past your typical session length or
        # set disabled = true.
        min_time = 2000;
      };
    };
  };
}
