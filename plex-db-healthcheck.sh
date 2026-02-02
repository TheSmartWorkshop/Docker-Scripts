#!/bin/bash

################################
#
# Written by: Joe @TheSmartWorkshop
#
# DISCLAIMER!! 
# Running Plex in particular on NFS is not supported, and generally not a good idea. I built this
# as a proof of concept, chasing the thought of "yeah but can it be done?". And it can.
# But it's not a good idea, and long-term, I would expect the failure rate on the database
# will be high, performance will be low, and not worth the gains in cluster placement.
# The script itself is valuable, in identifying the container name and node the container is running
# on in a Docker Swarm cluster for many other projects. 
# /Disclaimer
# 
# This bash script is designed to identify the current running Docker container
# within a Docker Swarm deployment, and what Docker host it is running on, for a
# deployed Plex Media Server. Once identified, it uses the Docker API to connect to the
# running container, and run a SQLite integrity check on the Plex database.
# You can adjust the actual "exec" part of the script to perform the action in the container you
# need.
#
################################

# Check if docker-compose is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed."
  exit 1
fi

# Get the deployment name from the command line argument
deployment_name="$1"

# Check if deployment name is provided. If not, we assume the stack name is just "plex"
if [ -z "$deployment_name" ]; then
  deployment_name="plex" # Force default if no argument is given
  echo "Usage: $0 <deployment_name>"
  echo "Using default deployment name: $deployment_name"
else
  echo "Using deployment name: $deployment_name"
fi

# Get the container name and node for running containers
stack_name=$(docker stack ps "$deployment_name" | grep "Running" | awk '{print $2}')
container_name=$(docker stack ps --no-trunc "$deployment_name" | grep "Running" | awk '{print $1}')
node_name=$(docker stack ps "$deployment_name" | grep "Running" | awk '{print $4}')

# Check if a container name and node were found
if [ -z "$container_name" ] || [ -z "$node_name" ]; then
  echo "Error: No running containers found for deployment '$deployment_name'."
  exit 1
fi

# Print the container name and node
echo "Container name for running deployment '$deployment_name': $stack_name.$container_name"
echo "Running on node: $node_name"

## This requires 2 things: hostnames must be resolvable, and hosts must have their Docker API accessable remotely, ie ExecStart -H tcp://0.0.0.0:2375
echo "Running Plex SQLite DB integrity Check..."
response=$(docker -H tcp://$node_name:2375 exec -it $stack_name.$container_name /usr/lib/plexmediaserver/Plex\ SQLite /config/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "PRAGMA integrity_check;")

#Check the response and return the appropreate exit code
if echo $response | grep "ok"; 
then
  exit 0
else
  exit 1
fi
