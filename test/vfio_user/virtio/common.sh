#  SPDX-License-Identifier: BSD-3-Clause
#  Copyright (C) 2022 Intel Corporation.
#  All rights reserved.

function vfu_tgt_run() {
	local vhost_name=$1
	local vfio_user_dir vfu_pid_file rpc_py
	shift

	vfio_user_dir=$(get_vhost_dir $vhost_name)
	vfu_pid_file="$vfio_user_dir/vhost.pid"
	rpc_py="$rootdir/scripts/rpc.py -s $vfio_user_dir/rpc.sock"

	mkdir -p $vfio_user_dir

	timing_enter vfu_tgt_start
	$rootdir/build/bin/vhost -r $vfio_user_dir/rpc.sock "$@" &
	vfupid=$!
	echo $vfupid > $vfu_pid_file

	echo "Process pid: $vfupid"
	echo "waiting for app to run..."
	waitforlisten $vfupid $vfio_user_dir/rpc.sock

	timing_exit vfu_tgt_start
}

# Print the endpoint creation option selecting a packed or split virtqueue.
function vfu_virtio_ring_opt() {
	case "$1" in
		packed) echo "--packed-ring" ;;
		split) ;;
		*)
			echo "Unsupported ring format: $1" >&2
			return 1
			;;
	esac
}
