#!/bin/sh

# Default value, in seconds, afterwhich the script should timeout waiting
# for server start. 
# Value here is overriden by value in my.cnf. 
# 0 means don't wait at all
# Negative numbers mean to wait indefinitely
service_startup_timeout=90

# The following variables are only set for letting mysql.server find things.

log_success_msg()
{
  echo " SUCCESS! $@"
}
log_failure_msg()
{
  echo " ERROR! $@"
}


mode=$1    # start, stop, restart, connect, status
if test -n "$1" ; then
  shift
fi


case `echo "testing\c"`,`echo -n testing` in
    *c*,-n*) echo_n=   echo_c=     ;;
    *c*,*)   echo_n=-n echo_c=     ;;
    *)       echo_n=   echo_c='\c' ;;
esac


case "$mode" in
  'start')
    # Start daemon

    echo $echo_n "Starting MariaDB"
    /usr/bin/mysqld_multi start
    sleep 3
    /usr/bin/mysql -u root -S /var/Mariadb/DEG_MGR_MD/mysql.sock -e "start slave;"
    sleep 3
    /usr/bin/mysql -u root -S /var/Mariadb/DEG_APP_MD/mysql.sock -e "start slave;"
    sleep 3 
    ;;

  'stop')
    # Stop daemon. We use a signal here to avoid having to know the
    # root password.
    echo $echo_n "Shutting down MySQL"
    /usr/bin/mysqld_multi stop
    ;;

  'restart')
    # Stop the service and regardless of whether it was
    # running or not, start it again.
    if $0 stop ; then
      $0 start 
    else
      log_failure_msg "Failed to stop running server, so refusing to try to start."
      exit 1
    fi
    ;;

    *)
      # usage
      echo "Usage: $0  {start|stop|restart}  [ MariaDB server options ]"
      exit 1
    ;;
esac

exit 0
