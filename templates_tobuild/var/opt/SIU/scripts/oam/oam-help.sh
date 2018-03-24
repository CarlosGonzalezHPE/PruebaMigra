#!/bin/bash
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

. /var/opt/<%SIU_INSTANCE%>/scripts/oam/oam-common.sh

echo
setColorTitle
[#SECTION_BEGIN:MANAGER#]
echo "OAM Tools on Manager '$(hostname)' - Help"
[#SECTION_END#]
[#SECTION_BEGIN:APP_SERVER#]
echo "OAM Tools on Application '$(hostname)' - Help"
[#SECTION_END#]
setColorNormal
echo
echo "oam-show_processes.sh    : show processes running status"
echo "oam-start_processes.sh   : start processes"
echo "oam-stop_processes.sh    : stop processes"
echo "oam-dump_blacklist.sh    : dump IMSI black list to output file"
echo "oam-load_blacklist.sh    : load IMSI black list from input file"
echo
