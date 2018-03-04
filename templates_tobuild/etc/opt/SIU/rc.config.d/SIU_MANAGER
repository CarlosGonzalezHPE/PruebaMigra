#!/bin/sh
#
# @(#) SIU - Z7092EA IUM (c) Copyright 1996-2003, Hewlett-Packard Company
#
# Smart Internet Usage startup control 

#
# Note: See the file /etc/opt/SIU/SIU.ini for additional
#       details of configuring the Smart Internet Usage product to
#       control run-time behavior of SIU applications and services.
#



# To execute the SIU admin agent daemon automatically at boot time,
# ensure the SIU_ADMIN_AGENT_SERVER_START variable below is set to 1.
# Any other value will disable the execution of the admin agent server
# daemon at bootup.  To start the daemon after bootup is complete, use
# the command SIUServer.

SIU_ADMIN_AGENT_SERVER_START=1
IUM_SERVICE_agent_START=${SIU_ADMIN_AGENT_SERVER_START}
module_agent_enabled=${SIU_ADMIN_AGENT_SERVER_START}

# To execute the Solid Database daemon automatically at boot time,
# ensure the SIU_MYSQL_START variable below is set to 1.  Any other
# value will disable the execution of the collectors.
# The Solid database should be started on all systems that have
# collectors.

SIU_DB_START=0
IUM_SERVICE_dbs_START=${SIU_DB_START}
module_dbs_enabled=${SIU_DB_START}

######
#
# SIU runtime variables.  These should not need to be changed
#
######

# Increase this number to allow more time for the SIU startup script to 
# determine the state of Adminagent.
SIU_ADMINAGENT_RETRY_COUNT=36


