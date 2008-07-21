# $Id$
#
# Build script for creating the BSDanywhere OpenBSD Live CD image.
#
# Copyright (c) 2008  Rene Maroufi, Stephan A. Rickauer
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

export RELEASE=4.3
export ARCH=i386
export R=$(echo $RELEASE | awk -F. '{print $1$2 }')

export IMAGE_ROOT=$BASE/image
export CACHE_ROOT=$BASE/cache

export MASTER_SITES=http://mirror.startek.ch
export PKG_PATH=http://mirror.switch.ch/ftp/pub/OpenBSD/$RELEASE/packages/$ARCH/:$MASTER_SITES/OpenBSD/pkg/$ARCH/e17/

export CWD=$(pwd)
export THIS_OS=$(uname)
export THIS_ARCH=$(uname -m)
export THIS_RELEASE=$(uname -r)

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

        echo -n 'This arch: '
        if [ "$THIS_ARCH" = "$ARCH" ]; then
            echo "$ARCH (ok)"
        else
            echo "$THIS_ARCH (NOT ok)"
            return 1
        fi

        echo -n 'This release: '
        if [ "$THIS_RELEASE" = "$RELEASE" ]; then
            echo "$RELEASE (ok)"
        else 
            echo "$THIS_RELEASE (NOT ok)"
            return 1
        fi

        echo -n "$BASE "
        if [ -d "$BASE" ]; then
            echo 'exists (ok)'
        else
            echo "doesn't exist (NOT ok)"
            return 1
        fi

        echo -n "$BASE "
        touch "$BASE/test" 
        if [ $? = '0'  ]; then 
            echo 'is writeable (ok)'
            rm $BASE/test
        else
            echo "isn't writable (NOT ok)"
            return 1
        fi
}

prepare_build() {
    echo -n 'Preparing build environment ... '
    test -d $IMAGE_ROOT && rm -rf $IMAGE_ROOT
    mkdir -p $IMAGE_ROOT
    mkdir -p $CACHE_ROOT
    echo done
}

# Get custom kernels.
install_custom_kernels() {
    for i in bsd bsd.mp
    do
        test -r $CACHE_ROOT/$i || \
             ftp -o $CACHE_ROOT/$i $MASTER_SITES/BSDanywhere/$RELEASE/$ARCH/$i
        cp -p $CACHE_ROOT/$i $IMAGE_ROOT/
    done
}

# Get generic boot loaders and ram disk kernel.
install_boot_files() {
    for i in cdbr cdboot bsd.rd
    do
        test -r $CACHE_ROOT/$i || \
             ftp -o $CACHE_ROOT/$i $MASTER_SITES/OpenBSD/stable/$RELEASE-stable/$ARCH/$i
        cp -p $CACHE_ROOT/$i $IMAGE_ROOT/
    done
}

# Get all OpenBSD file sets except compXX.tgz.
install_filesets() {
    for i in base game man misc etc xbase xetc xfont xserv xshare
    do
        test -r $CACHE_ROOT/$i$R.tgz || \
             ftp -o $CACHE_ROOT/$i$R.tgz $MASTER_SITES/OpenBSD/stable/$RELEASE-stable/$ARCH/$i$R.tgz
        echo -n "Installing $i ... "
        tar -C $IMAGE_ROOT -xzphf $CACHE_ROOT/$i$R.tgz
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
install_custom_kernels
install_boot_files
install_filesets
prepare_filesystem

# Help chroot to find a name server.
cp /etc/resolv.conf $IMAGE_ROOT/etc/

# Install modified OpenBSD template files.
install -o root -g wheel -m 644 $CWD/etc_fstab.tpl $IMAGE_ROOT/etc/fstab
install -o root -g wheel -m 644 $CWD/etc_myname.tpl $IMAGE_ROOT/etc/myname
install -o root -g wheel -m 644 $CWD/etc_motd.tpl $IMAGE_ROOT/etc/motd
install -o root -g wheel -m 644 $CWD/etc_boot.conf.tpl $IMAGE_ROOT/etc/boot.conf
install -o root -g wheel -m 644 $CWD/etc_hosts.tpl $IMAGE_ROOT/etc/hosts
install -o root -g wheel -m 644 $CWD/etc_sysctl.conf.tpl $IMAGE_ROOT/etc/sysctl.conf
install -o root -g wheel -m 755 $CWD/etc_rc.local.tpl $IMAGE_ROOT/etc/rc.local 
install -o root -g wheel -m 644 /dev/null $IMAGE_ROOT/fastboot

# Install BSDanywhere specific template files.
install -o root -g wheel -m 644 $CWD/etc_welcome.tpl $IMAGE_ROOT/etc/welcome
install -o root -g wheel -m 644 $CWD/etc_rc.restore.tpl $IMAGE_ROOT/etc/rc.restore
install -o root -g wheel -m 755 $CWD/usr_local_sbin_syncsys.tpl $IMAGE_ROOT/usr/local/sbin/syncsys

#
# Enter change-root and customize system within.
#
chroot $IMAGE_ROOT
ldconfig
echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# Create 'live' account with an empty password.
useradd -G wheel,operator,dialer -c "BSDanywhere Live CD Account" -d /home/live -k /etc/skel -s /bin/ksh -m live
perl -p -i -e 's/\Qlive:*************:1000\E/live::1000/g' /etc/master.passwd
pwd_mkdb /etc/master.passwd

# Download and install packages.
echo
pkg_add -x iperf nmap tightvnc-viewer rsync pftop trafshow pwgen hexedit hping mozilla-firefox mozilla-thunderbird gqview bzip2 epdfview ipcalc isearch BitchX imapfilter gimp abiword privoxy tor arping clamav e-20071211p3 audacious mutt-1.5.17p0-sasl-sidebar-compressed screen-4.0.3p1 sleuthkit smartmontools rsnapshot surfraw darkstat aescrypt aiccu amap angst httptunnel hydra iodine minicom nano nbtscan nepim netfwd netpipe ngrep

# To create /dev nodes and to untar all pre-packaged file systems
# into memory, we need to hook into /etc/rc early enough.
RC=/etc/rc
perl -p -i -e 's@# XXX \(root now writeable\)@$&\necho -n "Creating device nodes ... "; cp /stand/MAKEDEV /dev; cd /dev && ./MAKEDEV all; echo done@' $RC
perl -p -i -e 's@# XXX \(root now writeable\)@$&\n\necho -n "Populating file systems:"; for i in var etc root home; do echo -n " \$i"; tar -C / -zxphf /stand/\$i.tgz; done; echo .@' $RC
perl -p -i -e 's#^rm -f /fastboot##' $RC
perl -p -i -e 's#^(exit 0)$#cat /etc/welcome\n$&#g' $RC
# time marker for backups (which file was modified)
perl -p -i -e 's@^mount -uw /.*\n$@$&\ntouch /etc/timemark\n@' $RC
perl -p -i -e 's@/MAKEDEV all; echo done$@$&\n\n# exec restore script early\n/etc/rc.restore\n@' $RC

# Download torbutton extension and place it in live's home account for manual installation.
# Users can drag this file into firefox to install it. Automatic install seems to be broken.
ftp -o /home/live/torbutton.xpi http://torbutton.torproject.org/dev/releases/torbutton-1.2.0rc1.xpi

# Leave the chroot environment.
exit

# Install those template files that need prerequisites.
install -d -o 1000 -g 10 -m 555 $CWD/home_live_bin_mkbackup.tpl $IMAGE_ROOT/home/live/bin/mkbackup
install -d -o 1000 -g 10 -m 644 $CWD/home_live_.profile.tpl $IMAGE_ROOT/home/live/.profile
install -d -o 1000 -g 10 -m 644 $CWD/home_live_.kshrc.tpl $IMAGE_ROOT/home/live/.kshrc
install -d -o 1000 -g 10 -m 644 $CWD/home_live_.xinitrc.tpl $IMAGE_ROOT/home/live/.xinitrc
install -d -o 1000 -g 10 -m 644 $CWD/home_live_.e_e_applications_menu_favorite.menu.tpl $IMAGE_ROOT/home/live/.e/e/applications/menu/favorite.menu
install -d -o 1000 -g 10 -m 644 $CWD/home_live_.e_e_applications_bar_default_.order.tpl $IMAGE_ROOT/home/live/.e/e/applications/bar/default/.order
install -d -o root -g wheel -m 644 $CWD/usr_local_share_applications_xterm.desktop.tpl $IMAGE_ROOT/usr/local/share/applications/xterm.desktop
install -d -o root -g wheel -m 644 $CWD/etc_privoxy_config $IMAGE_ROOT/etc/privoxy/config

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
rm $IMAGE_ROOT/etc/resolv.conf

# To save space on the image, we clean out what is not needed to boot.
rm -r $IMAGE_ROOT/var/* && ln -s /var/tmp $IMAGE_ROOT/tmp
rm -r $IMAGE_ROOT/home/*
rm $IMAGE_ROOT/etc/fbtab

# Finally, create the image.
cd $IMAGE_ROOT/..
echo 'Creating ISO image.'
mkhybrid -A "BSDanywhere $RELEASE" -quiet -l -R -o bsdanywhere$R-$ARCH.iso -b cdbr -c boot.catalog image
