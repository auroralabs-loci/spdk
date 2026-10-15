#!/usr/bin/env bash
#  SPDX-License-Identifier: BSD-3-Clause
#  Copyright (C) 2026 Dell Inc.
#  All rights reserved.
#
set -e
testdir=$(readlink -f $(dirname $0))
rootdir=$(readlink -f $testdir/../../..)
source $rootdir/test/common/autotest_common.sh

if ! fio --enghelp=libblkio > /dev/null 2>&1; then
	echo "ERROR: fio with libblkio engine is required but not available"
	exit 1
fi

MALLOC_BDEV_SIZE=128
MALLOC_BLOCK_SIZE=512

timing_enter vhost_user

$rootdir/scripts/setup.sh

$SPDK_BIN_DIR/spdk_tgt -m 0x2 -S /var/tmp --wait-for-rpc &
spdk_pid=$!
trap '$rootdir/scripts/setup.sh reset; killprocess "$spdk_pid"; exit 1' SIGINT SIGTERM EXIT
waitforlisten $spdk_pid

$rpc_py iobuf_set_options --small-pool-count 16384 --small-bufsize 4096
$rpc_py framework_start_init
$rpc_py bdev_malloc_create $MALLOC_BDEV_SIZE $MALLOC_BLOCK_SIZE -b Malloc0
$rpc_py vhost_create_blk_controller blk0 Malloc0 --transport vhost_user_blk

fio $testdir/vhost_fio.job

trap - SIGINT SIGTERM EXIT
killprocess $spdk_pid
$rootdir/scripts/setup.sh reset
timing_exit vhost_user
