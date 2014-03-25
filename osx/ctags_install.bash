#!/bin/bash

git config --global init.templatedir '~/.dotfiles/git'
git config --global alias.ctags '!.git/hooks/ctags'

brew install ctags
gem install gem-browse
gem install gem-ctags
gem ctags
