#!/bin/bash

BINPATH="/usr/local/bin/dallebash"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo"
  exit 1
fi

cp dallebash.sh $BINPATH

if [ -f $BINPATH ]; then
  echo "dallebash already exists in /usr/local/bin. Overwrite? (y/n)"
  read -r response
  if [ "$response" != "y" ]; then
    echo "Installation aborted."
    exit 1
  fi
fi

if [ ! -f $BINPATH ]; then
  echo "Installation failed."
  exit 1
fi

chmod +x $BINPATH

touch ~/.openai_api_key
touch ~/.dalle_output_dir
touch ~/.dalle_config

echo "Installation complete. Use 'dallebash --wizard' to configure the script. For help and usage, use 'dallebash --help'."