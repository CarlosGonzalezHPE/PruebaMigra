#!/bin/bash

INPUT_FILEPATH=$1

awk 'BEGIN { show = 0; previous_line = "" } {
  if ($0 ~ " Received message = \\[" || $0 ~ " Sending response: \\[")
  {
    show = 1;
  }
  else
  {
    if ($0 ~ "^[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]")
    {
      show = 0;
    }

    if ($0 ~ "PGW TO DEG")
    {
      print $0;
    }
  }

  if (show == 1)
  {
    print $0;
  }

  previous_line = $0;
}' ${INPUT_FILEPATH}
