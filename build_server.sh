
#!/bin/bash

#----------------------------------------------------------------------------
#   The confidential and proprietary information contained in this file may
#   only be used by a person authorised under and to the extent permitted
#   by a subsisting licensing agreement from ARM Limited or its affiliates.
#
#          (C) COPYRIGHT 2013-2016 ARM Limited or its affiliates.
#              ALL RIGHTS RESERVED
#
#   This entire notice must be reproduced on all copies of this file
#   and copies of this file may only be made by a person if such person is
#   permitted to do so under the terms of a subsisting license agreement
#   from ARM Limited or its affiliates.
#----------------------------------------------------------------------------
# source (!) this file while at tree top - DO NOT run it

#CLEAN="$1"
bit_type=32
arch=x86

set -x

function make_dir()
{
	if [ ! -d "$1" ]; then
			mkdir -p $1
	fi
}
function build_module()
{
	cd $1
	
	make_dir arch/$arch/${bit_type}/obj
	make_dir arch/$arch/${bit_type}/lib
	
	make -j10 ARCH=$arch BIT_TYPE=$bit_type
	cd -
}
function compile_all()
{
	build_module tls
	build_module security_util
	build_module GuruxDLMS/development
	build_module tls

	##############################

	make_dir arch/$arch/${bit_type}/obj
	make_dir arch/$arch/${bit_type}/bin

	make -j10 ARCH=$arch BIT_TYPE=$bit_type
}

function clone_mbedtls()
{
	echo "clone mbed tls"
	cd tls
	git checkout mbedtls-2.7
	cp mbedtls/configs/config-suite-b.h  mbedtls/include/mbedtls/config.h
	cd -
}

function set_bit_type()
{
	is_gcc_32_bit=$(file -L /usr/bin/gcc | grep "ELF 32-bit")
	is_gcc_64_bit=$(file -L /usr/bin/gcc | grep "ELF 64-bit")

	is_gcc_arm_v7=$(file -L /usr/bin/gcc | grep "ARM, EABI5")
	is_gcc_arm_v8=$(file -L /usr/bin/gcc | grep "ARM aarch64")
	is_gcc_x86=$(file -L /usr/bin/gcc | grep -e "x86-64"  -e "Intel 80386")

	if [ ! -z "$is_gcc_64_bit" ]
	then
		bit_type=64
        elif [  ! -z "$is_gcc_32_bit" ]
        then
		bit_type=32
	else
		echo "Unknown bit type (32 or 64 bit).Aborting!!!"
		exit
        fi

	if [ ! -z "$is_gcc_arm_v7" ]
	then
		arch=arm-v7
	elif [  ! -z "$is_gcc_arm_v8" ]
	then
		arch=arm-v8
    elif [  ! -z "$is_gcc_x86" ]
    then
		arch=x86
	else
		echo "Unknown arch type (x86 or arm-v7/arm-v8).Aborting!!!"
		exit
    fi

	echo "This is $arch $bit_type native gcc"


}

function clean_all()
{
	echo "Clean all arch=$arch BIT_TYPE=$bit_type"
	make ARCH=$arch BIT_TYPE=$bit_type cleanall
	
}

while getopts ":a:b:c" o; do
case "${o}" in
	b)
		if [ "${OPTARG}" = "64" ]
		then
			bit_type=64
		elif [ "${OPTARG}" = "32" ]
		then
			bit_type=32
		else
			echo "incorrect bit type (${OPTARG}) , should be 64 or 32"
			exit 1
		fi
		;;
	a)
		if [ "${OPTARG}" = "x86" ]
		then
			arch=x86
		elif [ "${OPTARG}" = "arm-v7" ]
		then
			arch=arm-v7
		elif [ "${OPTARG}" = "arm-v8" ]
		then
			arch=arm-v8
		else
			echo "incorrect arch (${OPTARG}) , should be x86 or arm-v7/arm-v8"
			exit 1
		fi
		;;
	c)
		clean_all
		;;
	esac
done

#set_bit_type
clone_mbedtls
compile_all
