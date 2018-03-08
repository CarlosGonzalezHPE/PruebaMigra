#!/bin/bash
#-------------------------------------------------------------------------------
#
# Project : HP-DEG
#
# Version : 1.0
# Author : HP CMS
#
# Component: degvesrion.sh
# Description: Gives the Version Details of installed DEG .
#
#-------------------------------------------------------------------------------

. /home/ium/.bash_profile

[ -s /var/opt/${SIU_INSTANCE}/scripts/oam/degVersionCheck.jar ] && java -jar /var/opt/${SIU_INSTANCE}/scripts/oam/degVersionCheck.jar || echo "DEG Installation may be corrupt.  Re-install DEG or contact support"