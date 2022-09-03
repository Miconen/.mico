# Disabling mouse acceleration

## Getting your mouse Identifier

Utilizing `xinput list` and `xinput disable {id}` identifying your mouse id becomes trivial even if you're not sure about the mouses name.

## Xorg

Simply move the `50-mouse-acceleration.conf` file to `/etc/X11/xorg.conf.d/50-mouse-acceleration.conf` and reboot.
An alternative solution which won't persist after reboot but doesn't require a reboot to work either is `xinput --set-prop {id} "libinput Accel Profile Enabled" 0, 1`
