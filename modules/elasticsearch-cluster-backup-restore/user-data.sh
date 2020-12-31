#!/bin/bash
# This script adjust locale and installs jq on Amazon Linux 2 EC2 instance

echo -e "LANG=en_US.utf-8\nLC_ALL=en_US.utf-8" | sudo tee /etc/environment

sudo yum --assumeyes --quiet update

sudo yum --assumeyes --quiet install jq
