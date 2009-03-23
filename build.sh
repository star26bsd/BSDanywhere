# $Id$
#
# Build script for creating the BSDanywhere OpenBSD Live CD image.
#
# Copyright (c) 2009  Stephan A. Rickauer
# Copyright (c) 2008-2009  Rene Maroufi, Stephan A. Rickauer
#
# All rights reserved.
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# USAGE INFORMATION
# Call this script with 'cat build.sh | ksh'. Do NOT invoke build.sh
# directly as this will overwrite your entire / file system! Also
# ensure $BASE resides on file system mounted without restrictions.

#
# Variables
#
export BASE=/specify/base/path

export ARCH=$(uname -m)
export RELEASE=$(uname -r)
export R=$(echo $RELEASE | awk -F. '{print $1$2 }')

export IMAGE_ROOT=$BASE/image
export CACHE_ROOT=$BASE/cache

export MIRROR=http://mirror.switch.ch/ftp/pub/OpenBSD
export PKG_PATH=$MIRROR/$RELEASE/packages/$ARCH/:http://mirror.startek.ch/OpenBSD/packages/$RELEASE/$ARCH/

export CWD=$(pwd)
export THIS_OS=$(uname)
export MIN_SPACE_REQ='1600000'

export PKG_DBDIR=$IMAGE_ROOT/var/db/pkg

#
# Functions go first.
#
examine_environment() {

        echo -n 'Invocation: '
        if [ "$0" = 'ksh' ]; then
            echo 'via ksh (ok)'
        else
            echo "$0 directly (NOT ok)"
            return 1
        fi

        echo -n 'This user: '
        if [ "$USER" = 'root' ]; then
            echo 'root (ok)'
        else
            echo "$USER (NOT ok)"
            return 1
        fi

        echo -n 'This OS: '
        if [ "$THIS_OS" = 'OpenBSD' ]; then
            echo 'OpenBSD (ok)'
        else
            echo "$THIS_OS (NOT ok)"
            return 1
        fi

        echo -n "$BASE "
        if [ -d "$BASE" ]; then
            echo 'exists (ok)'
        else
            echo "doesn't exist (NOT ok)"
            return 1
        fi

        echo -n "Mount options of $BASE: "
        BASE_FS=$(df -P $BASE | grep ^/dev | awk '{print $1}')
        OPTIONS=$(mount | grep $BASE_FS | \
                  awk 'match($0,/\(.*\)/){print substr($0,RSTART+1,RLENGTH-2)}' |\
                  tr -d ',')

        for option in $OPTIONS
        do
            if [ "$option" = 'nodev' ] ||\
               [ "$option" = 'nosuid' ] ||\
               [ "$option" = 'noexec' ] ||\
               [ "$option" = 'noatime' ]
            then
               echo "$OPTIONS (NOT ok)"
               return 1
            fi
        done
        echo "$OPTIONS (ok)"

        echo -n "$BASE "
        touch "$BASE/test"
        if [ $? = '0'  ]; then
            echo 'is writeable (ok)'
            rm $BASE/test
        else
            echo "isn't writable (NOT ok)"
            return 1
        fi

        echo -n "Free space in $BASE: "
        test -d $IMAGE_ROOT && rm -rf $IMAGE_ROOT
        test -f $BASE/bsdanywhere$R-$ARCH.iso && rm -f $BASE/bsdanywhere$R-$ARCH.iso
        AVAIL=$(df -k | grep $BASE_FS | awk '{print $4}')
        if [ "$AVAIL" -ge "$MIN_SPACE_REQ" ]
        then
            echo "$AVAIL kb (ok)"
        else
            echo "$AVAIL kb (NOT ok)"
            return 1
        fi
}

prepare_build() {
    echo -n 'Preparing build environment ... '
    mkdir -p $IMAGE_ROOT
    mkdir -p $CACHE_ROOT
    echo done
}

# Get generic kernels and boot loaders.
install_boot_files() {
    for i in bsd bsd.mp cdbr cdboot
    do
	if [ ! -r "$CACHE_ROOT/$i" ]
	then
	     echo "$i not cached, fetching:"
	     ftp -Vo $CACHE_ROOT/$i $MIRROR/$RELEASE/$ARCH/$i
	fi
	echo -n "Installing $i ... "
	cp -p $CACHE_ROOT/$i $IMAGE_ROOT/
	echo done
    done
}

# Get all OpenBSD file sets except compXX.tgz.
install_filesets() {
    for fs in base game man misc etc xbase xetc xfont xserv xshare
    do
        fs=$fs$R.tgz
        if [ ! -r "$CACHE_ROOT/$fs" ]
        then
             echo "$fs not cached, fetching:"
             ftp -Vo $CACHE_ROOT/$fs $MIRROR/$RELEASE/$ARCH/$fs
        fi
        echo -n "Installing $fs ... "
        tar -C $IMAGE_ROOT -xzphf $CACHE_ROOT/$fs
        echo done
    done
}

# Create mfs mount point and device nodes. MAKEDEV is also saved to /stand so we'll 
# have it available for execution within mfs during boot (/dev will be overmounted).
prepare_filesystem() {
    echo -n 'Preparing file system layout ... '
    mkdir $IMAGE_ROOT/mfs
    cd $IMAGE_ROOT/dev && ./MAKEDEV all && cd $IMAGE_ROOT
    cp $IMAGE_ROOT/dev/MAKEDEV $IMAGE_ROOT/stand/
    echo done
}

examine_environment
[ $? = 0 ] || exit 1

prepare_build
install_boot_files
install_filesets
prepare_filesystem

# Install modified OpenBSD template files. Always make a backup copy so
# people can understand what the BSDanywhere specific modifications are.
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_fstab.tpl $IMAGE_ROOT/etc/fstab
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_myname.tpl $IMAGE_ROOT/etc/myname
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_motd.tpl $IMAGE_ROOT/etc/motd
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_boot.conf.tpl $IMAGE_ROOT/etc/boot.conf
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_hosts.tpl $IMAGE_ROOT/etc/hosts
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_sysctl.conf.tpl $IMAGE_ROOT/etc/sysctl.conf
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_rc.tpl $IMAGE_ROOT/etc/rc
install -b -B .orig -o root -g wheel -m 755 $CWD/etc_rc.local.tpl $IMAGE_ROOT/etc/rc.local 
install -b -B .orig -o root -g wheel -m 440 $CWD/etc_sudoers.tpl $IMAGE_ROOT/etc/sudoers
install -b -B .orig -o root -g wheel -m 600 $CWD/etc_master.passwd.tpl $IMAGE_ROOT/etc/master.passwd
install -b -B .orig -o root -g wheel -m 644 $CWD/etc_group.tpl $IMAGE_ROOT/etc/group
install -o root -g wheel -m 644 /dev/null $IMAGE_ROOT/fastboot

# Install BSDanywhere specific template files.
install -o root -g wheel -m 644 $CWD/etc_welcome.tpl $IMAGE_ROOT/etc/welcome
install -o root -g wheel -m 755 $CWD/etc_rc.restore.tpl $IMAGE_ROOT/etc/rc.restore
install -o root -g wheel -m 755 $CWD/usr_local_sbin_syncsys.tpl $IMAGE_ROOT/usr/local/sbin/syncsys

# Download and install packages.
pkg_add -x -B $IMAGE_ROOT/ $(grep -v '#' $CWD/tools/package_list)
    
# (Re-)Generate password databases.
pwd_mkdb -d $IMAGE_ROOT/etc/ $IMAGE_ROOT/etc/master.passwd

# Install those template files that need prerequisites.
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/bin/
install -o 1000 -g 10 -m 555 $CWD/home_live_bin_mkbackup.tpl $IMAGE_ROOT/home/live/bin/mkbackup
install -b -B .orig -o 1000 -g 10 -m 644 $CWD/home_live_.profile.tpl $IMAGE_ROOT/home/live/.profile
install -o 1000 -g 10 -m 644 $CWD/home_live_.kshrc.tpl $IMAGE_ROOT/home/live/.kshrc
install -o 1000 -g 10 -m 644 $CWD/home_live_.xinitrc.tpl $IMAGE_ROOT/home/live/.xinitrc
install -o root -g wheel -m 644 $CWD/usr_local_share_applications_xterm.desktop.tpl $IMAGE_ROOT/usr/local/share/applications/xterm.desktop

# E17 specific installs.
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.config/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.config/menus/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.e/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.e/e/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.e/e/applications/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.e/e/applications/menu/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.e/e/applications/bar/
install -d -o 1000 -g 10 -m 755 $IMAGE_ROOT/home/live/.e/e/applications/bar/default/
install -b -B .orig -o 1000 -g 10 -m 644 $CWD/home_live_.e_e_applications_menu_favorite.menu.tpl $IMAGE_ROOT/home/live/.e/e/applications/menu/favorite.menu
install -b -B .orig -o 1000 -g 10 -m 644 $CWD/home_live_.e_e_applications_bar_default_.order.tpl $IMAGE_ROOT/home/live/.e/e/applications/bar/default/.order
install -b -B .orig -o 1000 -g 10 -m 644 $CWD/home_live_.config_menus_applications.menu.tpl $IMAGE_ROOT/home/live/.config/menus/applications.menu

# Using gzexe we can compress binaries to speed up
# cdrom reads by saving space at the same time!
echo 'Compressing binary executables ... '
find $IMAGE_ROOT/bin \
     $IMAGE_ROOT/usr/bin \
     $IMAGE_ROOT/usr/sbin \
     $IMAGE_ROOT/usr/local/bin \
     $IMAGE_ROOT/usr/local/sbin \
     $IMAGE_ROOT/usr/X11R6/bin \
     ! -perm -4000 ! -name stty ! -name cp ! -name mkdir \
     ! -name chmod ! -name chgrp ! -name chown \
     ! -name tar ! -name pax ! -name cpio \
     ! -name sh ! -name ksh ! -name rksh \
     -type f -size +200 -exec gzexe {} \;

echo -n 'Removing gzexe ~ copies ... '
find $IMAGE_ROOT/bin \
     $IMAGE_ROOT/usr/bin \
     $IMAGE_ROOT/usr/sbin \
     $IMAGE_ROOT/usr/local/bin \
     $IMAGE_ROOT/usr/local/sbin \
     $IMAGE_ROOT/usr/X11R6/bin -type f -name "*~" -exec rm {} \;
echo 'done'

# Prepare to-be-mfs file systems by packaging their directories into
# individual tgz's. They will be untar'ed on each boot by /etc/rc.
# This will greatly reduce boot time compared to using -P in newfs.
for fs in var etc root home
do
    echo -n "Packaging $fs ... "
    tar cphf - $fs | gzip -9 > $IMAGE_ROOT/stand/$fs.tgz
    echo done
done

# Cleanup build environment.
rm /tmp/gzexe*

# To save space on the image, we clean out what is not needed to boot.
rm -r $IMAGE_ROOT/var/* && ln -s /var/tmp $IMAGE_ROOT/tmp
rm -r $IMAGE_ROOT/home/*
rm $IMAGE_ROOT/etc/fbtab

# Finally, create the image.
cd $IMAGE_ROOT/..
echo 'Creating ISO image:'
mkhybrid -A "BSDanywhere $RELEASE" -quiet -l -R -o bsdanywhere$R-$ARCH.iso -b cdbr -c boot.catalog image
