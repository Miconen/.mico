{
  ...
}:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    # Needs a Nerd Font (maple-mono.NF).
    presets = [ "catppuccin-powerline" ];

    # Deep-merged over the preset.
    settings = {
      add_newline = false;

      cmd_duration = {
        # The preset notifies on every long interactive command (e.g. closing nvim).
        show_notifications = false;
        min_time = 2000;
      };
    };
  };
}
