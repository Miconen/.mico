#!/bin/bash

systemctl --user daemon-reload
systemctl --user enable backup-package-list.timer
systemctl --user start backup-package-list.timer
