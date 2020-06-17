# Greenbone Vulnerability Management 11 Docker Image

This docker image is based on GVM 11 in order to provide a clean, reliable vulnerability scanning image for quick deployment.

## Table of contents

* [Quick Start](#quick-start)
* [How to use](#how-to-use)
  * [Accessing Web Interface](#accessing-web-interface)
* [All Environment Variables](all-environment-variables)

## Quick start

**Install docker**

If you have Ubuntu you can use the docker.io package.
```bash
apt install docker.io
```

You can also use the docker install script by running:
```bash
curl https://get.docker.com | sh
```

**Running the container**

This command will pull, create, and start the container with an attached volume:

```shell
docker run --detach --publish 443:9392 --env PASSWORD="Admin password here" --volume gvm-data:/openvas --name gvm dangasper/openvaseleven:latest
```

During this time the start.sh script will be running inside the docker container. This script handles setting up the gvm user and gvm feed sync user. In the event this is a fresh run, or no previous openvas database is linked via a volume, a new one will be created and configured. Once this is completed the script will update the NVT, SCAP, and CERT feeds, then start the core services.
Depending on your hardware, it can take up to 10+ minutes while the feeds are updated and the database is rebuilt.


## All Environment Variables

| Name     | Description                            | Default Value |
| -------- | -------------------------------------- | ------------- |
| USERNAME | Default admin username                 | admin         |
| PASSWORD | Default admin password                 | admin         |
| HTTPS    | If the web ui should use https vs http | true          |

## How to use

General information on using the image

### Accessing the web interface

Access web interface using the IP address of the docker host on port 443 - `https://<IP address>`

Default credentials:
```shell
Username: admin
Password: admin
```

### Monitoring scan progress

This command will show you the GVM processes running inside the container:
```shell
docker top gvm
```

### Checking the GVM logs

All the logs from /usr/local/var/log/gvm/* can be viewed by running:
```shell
docker logs gvm
```

### Updating the NVTs

The NVTs will update every time the container starts. Even if you leave your container running 24/7, the easiest way to update your NVTs is to restart the container.
```shell
docker restart gvm
```