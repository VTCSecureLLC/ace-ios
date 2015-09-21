#!/bin/bash

# git_version.sh
#
# Copyright (C) 2012  Belledonne Comunications, Grenoble, France
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# Created by Gautier Pelloux-Prayer on 2014/11/03.
# Generate Classes/git_version.h which contains GIT_VERSION preprocessor macro

short_sha1=$(git rev-parse --short HEAD)
major_minor_patch=$(bundle exec semver format '%M.%m.%p')
special_build=$(bundle exec semver format '%M.%m.%p')

defaults write linphone-Info.plist CFBundleShortVersionString "$major_minor_patch"
defaults write linphone-Info.plist CFBundleVersion "${TRAVIS_BUILD_NUMBER:-1}"

linphone_ios_version="$(bundle exec semver format '%M.%m.%p')-${TRAVIS_BUILD_NUMBER:-1}-${short_sha1}"

printf "/* LinphoneIOSVersion.h
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#define LINPHONE_IOS_VERSION \"$linphone_ios_version\"
" > $(dirname $0)/../Classes/LinphoneIOSVersion.h

