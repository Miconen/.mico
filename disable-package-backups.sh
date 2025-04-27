#!/bin/bash

systemctl --user stop backup-package-list.timer
systemctl --user disable backup-package-list.timer
systemctl --user deamon-reload
