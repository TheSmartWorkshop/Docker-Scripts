A collection of scripts helpful for Docker environments!

# Plex DB integrity check
`plex-db-healthcheck.sh`

This script finds a running Plex Media Server container deployed to a Docker Swarm cluster, and identifies th full container name with the randomized ID, as well as which host it is currently running on. Next it uses the Docker API to run a SQLite database integrity check, and returns the result. A standared `exit 0` response is generated from SQLite responding with `ok`, and any other response is considered an error, and the script returns `exit 1`. 

The script assumes your Plex stack deployment is named `plex` (ie: `docker stack deploy -c docker-compose.yml plex`) however if it is named anything else, you can pass that as an attribute in the script, (ie: `./plex-db-healthcheck.sh myActualPlexStackName`)

## Installation
* Pull `plex-db-healthcheck.sh` file down or clone the repo fully (ie: `git clone https://github.com/TheSmartWorkshop/Docker-Scripts.git`)
* Make the script executable:  
`chmod +x plex-db-healthcheck.sh`
* Make sure you review the prerequisites below

## Prerequisites
To run this script successfully, you need two things in your Docker Swarm cluster environment:
* All of your docker node hostnames (ie: `docker nods ls`) need to be DNS-resolvable. Make static DNS entries, `/etc/hosts` entries, whatever you like. 
* All nodes in your cluster need to have the Docker API accessible externally:

### Docker API
In typical Debian-based systemd deployments, this will work

* Edit the `docker.service` file:  
`sudo nano /lib/systemd/system/docker.service`

* Find the `ExecStart` line and add the external listener:  
`-H tcp://0.0.0.0:2375`

* Your ExecStart line should look something like this now:  
`ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd/sock`

* Save and exit the file, then reload systemctl daemon so it knows about the change:  
`sudo systemctl daemon-reload`
* Then restart docker:  
`sudo systemctl restart docker.service`  

You should be able to connect to the docker API from other hosts on your network now.
