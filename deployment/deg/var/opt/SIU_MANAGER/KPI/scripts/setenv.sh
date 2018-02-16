#!/bin/bash
#-------------------------------------------------------------------------------
#
# Project : HP-DEG
#
# Version : 1.0                                                                 
# Author : HP CMS
#
# Component: setenv.sh
# Description: Environment variables for KPI tool.
#
#-------------------------------------------------------------------------------

. /home/ium/.bash_profile

JAVA_HOME=$JAVA_HOME

cd ..
APPROOT=$PWD

JAVA_LIB=$APPROOT/lib
CLASSPATH=.:$APPROOT/config:$JAVA_LIB
for i in $JAVA_LIB/*.jar ; do
    CLASSPATH=$CLASSPATH:$i
done

IUM_LIB=/opt/SIU_MANAGER
CLASSPATH=$CLASSPATH:$IUM_LIB/lib/mariadb-java-client-2.2.0.jar
LD_LIBRARY_PATH=$IUM_LIB/lib/
SHLIB_PATH=$IUM_LIB/lib/


export JAVA_LIB
export CLASSPATH
export JAVA_HOME
export SHLIB_PATH
export LD_LIBRARY_PATH
