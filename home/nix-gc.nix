{
  pkgs,
  ...
}:
{
  # home-manager has no `nix.gc` option (there is no modules/misc/nix.nix at
  # all), so the garbage collector is a hand-written user timer.
  #
  # This only collects THIS user's garbage. Store-wide deduplication
  # (auto-optimise-store) is a daemon setting that requires root and therefore
  # cannot live here - see the README for the one-line /etc/nix/nix.conf step.
  systemd.user.services.nix-gc = {
    Unit.Description = "Collect old nix generations and unreachable store paths";

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 30d";
    };
  };

  systemd.user.timers.nix-gc = {
    Unit.Description = "Weekly nix garbage collection";

    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    Install.WantedBy = [ "timers.target" ];
  };
}
