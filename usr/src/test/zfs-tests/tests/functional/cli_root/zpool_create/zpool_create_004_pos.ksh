#!/usr/bin/ksh
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2012, 2014 by Delphix. All rights reserved.
#

. $STF_SUITE/tests/functional/cli_root/zpool_create/zpool_create.shlib

#
# DESCRIPTION:
# Create a storage pool with many file based vdevs.
#
# STRATEGY:
# 1. Create assigned number of files in ZFS filesystem as vdevs.
# 2. Creating a new pool based on the vdevs should work.
# 3. Creating a pool with a file based vdev that is too small should fail.
#

verify_runnable "global"

function cleanup
{
	typeset pool=""

	poolexists $TESTPOOL1 && destroy_pool $TESTPOOL1
	poolexists $TESTPOOL && destroy_pool $TESTPOOL

	[[ -d $TESTDIR ]] && log_must $RM -rf $TESTDIR
	partition_disk $SIZE $disk 6
}

log_assert "Storage pools with $VDEVS_NUM file based vdevs can be created."
log_onexit cleanup

disk=${DISKS%% *}
create_pool $TESTPOOL $disk
log_must $ZFS create -o mountpoint=$TESTDIR $TESTPOOL/$TESTFS

vdevs_list=$($ECHO $TESTDIR/file.{01..32})
log_must $MKFILE 64m $vdevs_list

create_pool "$TESTPOOL1" $vdevs_list
log_must vdevs_in_pool "$TESTPOOL1" "$vdevs_list"

if poolexists $TESTPOOL1; then
	destroy_pool $TESTPOOL1
else
	log_fail "Creating pool with large numbers of file-vdevs failed."
fi

log_must $MKFILE 32m $TESTDIR/broken_file
vdevs_list="$vdevs_list ${TESTDIR}/broken_file"
log_mustnot $ZPOOL create -f $TESTPOOL1 $vdevs_list

log_pass "Storage pools with many file based vdevs can be created."
