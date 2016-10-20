#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

function spawn_fork {
local run_this=$1
$run_this &
}
BREW=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)
spawn_fork "wget --no-check-certificate https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/master/gas-preprocessor.pl && chmod +x gas-preprocessor.pl && sudo mv -f gas-preprocessor.pl /usr/local/bin "
spawn_fork "bundle install"
spawn_fork " /usr/bin/ruby -e  $BREW  && brew update 1>/dev/null && brew install doxygen nasm yasm optipng imagemagick intltool ninja antlr cmake &&   sudo ln -sf /usr/local/bin/glibtoolize /usr/local/bin/libtoolize "
spawn_fork "git submodule update --init --recursive" 

wait

( sleep 1000 ; ps -eo state,ppid | awk '$1=="Z"{cmd="kill -9 "$2;system(cmd) }') &
