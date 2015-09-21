#!/bin/bash
# Author: Ian Blenke <ian@blenke.com>
# Purpose: Prepare and build linphone for Mac
# Note: This script is idempotent, and should be runnable multiple times in succession without issue.

#export HOMEBREW_GITHUB_API_TOKEN=

set -ex

sudo perl -pi -e 's/^#%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Make it so we aren't prompted for a password for sudo
dscl . read /Groups/wheel GroupMembership | grep $(whoami) || \
  sudo dscl . append /Groups/wheel GroupMembership $(whoami)

which brew || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew upgrade
#brew doctor

brew install caskroom/cask/brew-cask
brew cask install java

[ -x /usr/bin/xcode-select ] || sudo ln -s /usr/bin/true /usr/bin/xcode-select

brew install doxygen nasm yasm optipng imagemagick coreutils intltool gettext ninja cmake make

[ -e /usr/local/bin/make ] || ln -s /usr/local/bin/gmake /usr/local/bin/make

# This is needed for ruby 1.8 compatibility when building under 10.7/10.8
( export PATH=/usr/local/bin:$PATH; brew install vim )

sudo mkdir -p /opt
sudo chmod 1777 /opt
[ -h /opt/local ] || ln -s /usr/local /opt/local

brew install intltool libtool wget pkg-config automake \
             speex ffmpeg readline libvpx opus

[ -h /usr/local/bin/libtoolize ] || \
(
  [ -f /usr/local/bin/libtoolize ] && rm -f /usr/local/bin/libtoolize
  [ -h /usr/local/bin/libtoolize ] || \
    ln -s /usr/local/bin/glibtoolize /usr/local/bin/libtoolize
)

export MACOSX_DEPLOYMENT_TARGET=10.7
export LDFLAGS="-Wl,-headerpad_max_install_names"

brew install homebrew/dupes/m4
brew link --force m4
[ -x /usr/bin/m4 ] || ln -sf /usr/local/bin/m4 /usr/bin/m4

brew tap Gui13/linphone
brew install antlr3.2 libantlr3.4c gtk-mac-integration srtp libgsm

brew install pixman
brew link --force pixman
brew install fontconfig
brew link --force fontconfig
brew install freetype
brew link --force freetype
brew install libpng
brew link --force libpng
brew install cairo --without-x11
brew link --force cairo
brew install gtk+ --without-x11
brew install ianblenke/taps/gnome-common --without-x11
brew install hicolor-icon-theme

[ -d /opt/polarssl ] || \
(
  cd /opt
  git clone git://git.linphone.org/polarssl.git polarssl || ( rm -fr polarssl ; exit 1 )
  cd polarssl
  ./autogen.sh && ./configure --prefix=/usr/local && make && make install || ( rm -fr polarssl ; exit 1 )
)

[ -d /opt/bzrtp ] || (
  cd /opt
  ( git clone git://git.linphone.org/bzrtp.git && cd bzrtp && ./autogen.sh && ./configure --prefix=/usr/local && make && make install ) || ( rm -fr bzrtp ; exit 1)
)

[ -d /opt/belle-sip ] || \
(
  cd /opt
  git clone git://git.linphone.org/belle-sip.git || ( rm -fr /opt/belle-sip ; exit 1)
  cd belle-sip
  ./autogen.sh && ./configure --prefix=/usr/local && make && make install || ( rm -fr /opt/belle-sip ; exit 1)
)
  
brew link --force gettext
brew link --force readline

brew install shared-mime-info glib-networking hicolor-icon-theme
update-mime-database /usr/local/share/mime

[ -d /opt/gtk-mac-bundler ] || \
(
    cd /opt
    git clone https://github.com/jralls/gtk-mac-bundler.git || ( rm -fr gtk-mac-bundler ; exit 1)
    cd gtk-mac-bundler
    git checkout 6e2ed855aaeae43c29436c342ae83568573b5636 || ( rm -fr gtk-mac-bundler ; exit 1)
    make install || ( rm -fr gtk-mac-bundler ; exit 1)
    touch /usr/local/lib/charset.alias
)

export PATH=$PATH:~/.local/bin

[ -d /opt/gtk-quartz-engine ] || \
(
  cd /opt
  git clone https://github.com/jralls/gtk-quartz-engine.git || ( rm -fr /opt/gtk-quartz-engine ; exit 1 )
  cd gtk-quartz-engine
  ./autogen.sh && ./configure --prefix=/usr/local && CFLAGS="$CFLAGS -Wno-error" make install || ( rm -fr /opt/gtk-quartz-engine ; exit 1 )
)


[ -d /opt/linphone ] || \
(
  git clone https://github.com/VTCSecureLLC/linphone /opt/linphone || ( rm -fr linphone ; exit 1 )
)

cd /opt/linphone
git submodule update --init --recursive

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
./autogen.sh
./configure --prefix=/usr/local --with-srtp=/usr/local --with-gsm=/usr/local --enable-zrtp --disable-strict --enable-relativeprefix --enable-dtls --with-polarssl=/usr/local --with-ffmpeg=/usr/local --enable-truespeech --enable-ipv6 --enable-video --disable-x11 --without-libintl-prefix

for otoolpath in /usr/bin/otool /Library/Developer/CommandLineTools/usr/bin/otool ; do
  [ -f "$otoolpath".bin ] || \
  (
    sudo mv "$otoolpath" "$otoolpath".bin
    cat <<EOF > /tmp/otool.$$
#!/bin/bash
[ -d /opt/linphone/.Linphone.app ] && find /opt/linphone/.Linphone.app/ -type l | while read line; do [ -h "\$line" ] && rsync -aq \$(dirname \$(readlink "\$line" | sed -e 's%\.\..*Cellar%/usr/local/Cellar%'))/ \$(dirname "\$line")/ ; done
exec \$0.bin \$@
EOF
    sudo mv /tmp/otool.$$ "$otoolpath"
    sudo chmod 755 "$otoolpath"
  )
done


make clean
make
make install
make -C oRTP install
make -C mediastreamer2 install
make bundle

# Now fix all of the relocatable libraries
find Linphone.app/ -name '*.dylib' | grep -v Linphone.app//Contents/Resources/lib | while read library; do mv -f $library Linphone.app//Contents/Resources/lib/; done

for library in Linphone.app/Contents/Resources/lib/*.dylib ; do
  otool -L "$library" | \
  (
    read source
    origin=$(echo $source | sed -e 's/:$//')
    chmod 644 $origin
    install_name_tool -id "@loader_path/$(basename $origin)" "./$origin"
    grep -e '/usr/local' | awk '{print $1}' | sed -e 's%^/usr/local/%%' | \
    (
      while read file ; do \
        [ -e Linphone.app/Contents/Resources/$file ] || (
          ln -sf $(echo -n $(dirname $file) | sed -e 's%[^\\/]*%..%g')/lib/$(basename $file) Linphone.app/Contents/Resources/$file 
        )
        install_name_tool -change "/usr/local/$file" "@loader_path/$(basename $file)" "./$origin"
      done
    )
  )
done

gdk-pixbuf-query-loaders > ./Linphone.app/Contents/Resources/etc/gtk-2.0/gdk-pixbuf.loaders

pango-querymodules > './Linphone.app/Contents/Resources/etc/pango/pango.modules'

