#!/usr/bin/env bash
if ! test -d "/Applications/Google Chrome.app"
then
  >&2 echo "Chrome is not installed. Install it with Homebrew: \
brew cask install google-chrome"
  exit 1
fi
  mkdir -p ~/.chrome/$1
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
--user-data-dir=~/.chrome/$1 &
