#!/bin/sh

# --- clean-up artifacts after build to recover disk space
sudo rm -rf $HOME/src/*
sudo rm -rf $HOME/gits/FS
sudo rm -rf $HOME/gits/red5/.git

# clear out some other stuff
sudo rm -rf /usr/share/man      # about 20MB with gz files (uncompressible), perhaps better to do this with yum/rpm?
sudo rm -rf /usr/share/doc
sudo rm -rf /usr/share/selinux  # I personally take great pleasure in this one

