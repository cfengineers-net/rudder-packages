#!/bin/bash -e

. $PWD/vars/common
. $PWD/vars/rudder.$OS.2.10.0
. $PWD/vars/exports
. $PWD/functions/build/common
. $PWD/functions/package/common

builder
packager

