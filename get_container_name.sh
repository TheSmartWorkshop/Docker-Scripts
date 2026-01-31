#!/bin/bash

# Check if docker-compose is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed."
  exit 1
fi

# Get the deployment name from the command line argument
deployment_name="$1"

# Check if deployment name is provided
if [ -z "$deployment_name" ]; then
  echo "Usage: $0 <deployment_name>"
  exit 1
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
docker -H tcp://$node_name:2375 exec -it $stack_name.$container_name /usr/lib/plexmediaserver/Plex\ SQLite /config/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "PRAGMA integrity_check;"
