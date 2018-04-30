#!/bin/bash

awk -v DEBUG=classifyThreads.debug -v OUT=classifyThreads.out '
BEGIN {
  found_dates = 0;
}
{
  line = $0;

  if (match(line, /^[0-9]+-[0-9]+-[0-9]+\s[0-9]+:[0-9]+:[0-9]+/)) {
    previous_date = date;
    date = line;
    if (found_dates++ > 1) {
      print previous_date" --------------------------------------------------------------------------------" >> OUT;
      print previous_date" --------------------------------------------------------------------------------" >> DEBUG;
      n = asorti(threads, ind);
      for (i = 1; i <= n; i++) {
        print "threads["threadNumber"] = "threads[threadNumber] >> DEBUG;
        threadNumber = ind[i];
        if (previousThreads[threadNumber] != "") {
          if (threads[threadNumber] == previousThreads[threadNumber]) {
            print previous_date" EQU thread[#"threadNumber"] "threads[threadNumber] >> OUT;
          } else {
            print previous_date" DIF thread[#"threadNumber"] "threads[threadNumber] >> OUT;
          }
        } else {
          print previous_date" NEW thread[#"threadNumber"] "threads[threadNumber] >> OUT;
        }
      }

      n = asorti(previousThreads, ind);
      for (i = 1; i <= n; i++) {
        threadNumber = ind[i];
        print "previousThreads["threadNumber"] = "previousThreads[threadNumber] >> DEBUG;
        print "threads["threadNumber"] = "threads[threadNumber] >> DEBUG;

        if (threads[threadNumber] == "") {
          if (previousThreads[threadNumber] != "") {
            print previous_date" DEL thread[#"threadNumber"] "previousThreads[threadNumber] >> OUT;
          }
        }
      }

      delete previousThreads;

      n = asorti(threads, ind);
      for (i = 1; i <= n; i++) {
        threadNumber = ind[i];
        previousThreads[threadNumber] = threads[threadNumber];
      }

      delete threads;
    }
    next;
  }

  if (match(line, /\x22(.+)\x22\s#([0-9]+)\s/, v)) {
    label = v[1];
    threadNumber = sprintf("%3.3d", v[2]);
    threads[threadNumber] = label;
    print "threads["threadNumber"] = "threads[threadNumber] >> DEBUG;
  }
}'
