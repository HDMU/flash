#!/bin/bash

CURDIR=$1

if [ -d $CURDIR/../../apps/libstb-hal-next ]; then
	HAL_REV=_HAL-rev`cd $CURDIR/../../apps/libstb-hal-next && git log | grep "^commit" | wc -l`-next
elif [ -d $CURDIR/../../apps/libstb-hal-github ]; then
	HAL_REV=_HAL-rev`cd $CURDIR/../../apps/libstb-hal-github && git log | grep "^commit" | wc -l`-github
elif [ -d $CURDIR/../../apps/libstb-hal-martii-github ]; then
	HAL_REV=_HAL-rev`cd $CURDIR/../../apps/libstb-hal-martii-github && git log | grep "^commit" | wc -l`-martii-github
else
	HAL_REV=_HAL-rev`cd $CURDIR/../../apps/libstb-hal && git log | grep "^commit" | wc -l`
fi

if [ -d $CURDIR/../../apps/neutrino-mp-next ]; then
	NMP_REV=_NMP-rev`cd $CURDIR/../../apps/neutrino-mp-next && git log | grep "^commit" | wc -l`-next
elif [ -d $CURDIR/../../apps/neutrino-mp-github ]; then
	NMP_REV=_NMP-rev`cd $CURDIR/../../apps/neutrino-mp-github && git log | grep "^commit" | wc -l`-github
elif [ -d $CURDIR/../../apps/neutrino-mp-martii-github ]; then
	NMP_REV=_NMP-rev`cd $CURDIR/../../apps/neutrino-mp-martii-github && git log | grep "^commit" | wc -l`-martii-github
else
	NMP_REV=_NMP-rev`cd $CURDIR/../../apps/neutrino-mp && git log | grep "^commit" | wc -l`
fi

gitversion="_BASE-rev`(cd $CURDIR/../../cdk && git log | grep "^commit" | wc -l)`$HAL_REV$NMP_REV"

echo $gitversion
#export gitversion
