# $OpenBSD: sudoers,v 1.21 2008/04/11 20:51:57 thib Exp $
#
# sudoers file.
#
# This file MUST be edited with the 'visudo' command as root.
# Failure to use 'visudo' may result in syntax or file permission errors
# that prevent sudo from running.
#
# See the sudoers man page for the details on how to write a sudoers file.
#

# Host alias specification

# User alias specification

# Cmnd alias specification

# Defaults specification
Defaults env_keep +="DESTDIR FETCH_CMD FLAVOR FTPMODE GROUP MAKE MULTI_PACKAGES"
Defaults env_keep +="OKAY_FILES OWNER PKG_DBDIR PKG_DESTDIR PKG_CACHE PKG_PATH"
Defaults env_keep +="PKG_TMPDIR PORTSDIR RELEASEDIR SUBPACKAGE WRKOBJDIR"
Defaults env_keep +="SSH_AUTH_SOCK EDITOR VISUAL SHARED_ONLY"

# Uncomment to disable the lecture the first time you run sudo
#Defaults !lecture

# Uncomment to preserve the environment for users in group wheel
#Defaults:%wheel !env_reset

# Runas alias specification

# User privilege specification
root	ALL=(ALL) SETENV: ALL

# Uncomment to allow people in group wheel to run all commands
# and set environment variables.
%wheel	ALL=(ALL) SETENV: ALL

# Same thing without a password
# %wheel	ALL=(ALL) NOPASSWD: SETENV: ALL

# Samples
# %users  ALL=/sbin/mount /cdrom,/sbin/umount /cdrom
# %users  localhost=/sbin/shutdown -h now
