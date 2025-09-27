#!/usr/bin/env bash

# Checks the scoring every minute

while true; do
  ./scoring.sh 10.0.0.10 10.0.0.11 #REPLACE IPS
  echo "---- $(date) ----"
  sleep 60
done

