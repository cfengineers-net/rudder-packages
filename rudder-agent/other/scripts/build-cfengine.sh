#!/bin/bash -e

. $PWD/vars/common

. $PWD/vars/cfengine.$OS.$1
. $PWD/vars/exports

. $PWD/functions/build/common
. $PWD/functions/package/common

builder
packager
