#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

which brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"



wget --no-check-certificate https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/master/gas-preprocessor.pl && chmod +x gas-preprocessor.pl && sudo mv -f gas-preprocessor.pl /usr/local/bin &
bundle install &

cat .gitmodules | grep -o '".*"' | cut -d '"' -f 2 | while sleep 2 && read line; do git submodule update --init --recursive $line & done
# make sure everything is fetched

git submodule update --init --recursive &
brew update 1>/dev/null && brew install doxygen nasm yasm optipng imagemagick intltool ninja antlr cmake 

[ -x /usr/local/bin/libtoolize ] || sudo ln -sf /usr/local/bin/glibtoolize /usr/local/bin/libtoolize

#pushd /usr/local/Library/Homebrew/; git branch --set-upstream-to=origin/master master ; git pull ; popd


