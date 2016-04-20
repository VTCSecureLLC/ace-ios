#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

function spawn_fork {
local run_this=$1 wait_for=${2:-1000}
bash -c "$run_this" &
local dat_pid=$!
( sleep $wait_for ; if kill -0 $dat_pid ; then kill $dat_pid ; fi ) &
}

spawn_fork "wget --no-check-certificate https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/master/gas-preprocessor.pl && chmod +x gas-preprocessor.pl && sudo mv -f gas-preprocessor.pl /usr/local/bin "
spawn_fork "bundle install" 
spawn_fork "( which brew || /usr/bin/ruby -e  \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\") && brew update 1>/dev/null && brew install doxygen nasm yasm optipng imagemagick intltool ninja antlr cmake &&  ([ -x /usr/local/bin/libtoolize ] || sudo ln -sf /usr/local/bin/glibtoolize /usr/local/bin/libtoolize )" 
spawn_fork "git submodule update --init --recursive" 

wait
