#!/bin/bash

echo "Starting to Install custom plugins"
## For each custom plugin
## cd /usr/local/custom/kong/plugins/<plugin_name>
## luarocks make

luarocks install lunajson

cd /usr/local/custom/kong/plugins/jwt-backend
luarocks make

echo "Done Installing custom plugins"