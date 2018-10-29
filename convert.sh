#!/usr/bin/env bash

if [ "$#" -eq 0 ]; then
  echo "You need to give a file name to convert"
  exit 1
fi


filename="${1}"
filename_base=$(echo "${filename}" | cut -f 1 -d '.')

pandoc "${filename}" -f markdown -t html -s -o "${filename_base}".html

exit $?

