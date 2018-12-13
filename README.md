# JARVICE File Manager 

The JARVICE File Manager is a browser-based service that allows you to easily upload and download files from the Nimbix Cloud.

This project builds the Docker container for the JARVICE file manger App on the [NIMBIX cloud](https://www.nimbix.net/platform/)

## Getting Started

These instructions will create the Docker container needed to create a JARVICE file manager App on the NIMBIX cloud using [PushToCompute](https://jarvice.readthedocs.io/en/latest/cicd/) 

### Prerequisites

You will need:
* Docker
* JARVICE account (create an App w/ PushToCompute)
* Docker registry (e.g. [DockerHub](https://hub.docker.com/))

#### Installing Docker on Ubuntu

```
apt-get update && apt-get install -y curl lsb-core gnupg
LSB_REL_NAME=$(lsb_release -c | awk '{print $2}')
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
DEBARCH=$(dpkg --print-architecture) && echo "deb [arch=$DEBARCH] https://download.docker.com/linux/ubuntu ${LSB_REL_NAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update && apt-get install -y docker-ce
```

#### Installing Docker on CentOS

```
yum install -y curl gnupg
TMP_FILE=$(mktemp)
curl -fsSL https://download.docker.com/linux/centos/gpg > ${TMP_FILE}
rpm --import ${TMP_FILE} && rm -f ${TMP_FILE}
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce
yum install -y docker-ce
```

#### Install Docker on MacOSX

Follow these [instructions](https://docs.docker.com/docker-for-mac/install/)

#### Create JARVICE Account

[Sign up here](https://www.nimbix.net/contact-us/)

### Building Docker Container 

A Docker container is used to create an App using the [PushToCompute flow](https://jarvice.readthedocs.io/en/latest/cicd/) on JARVICE.

```
# Clone this repository
git clone https://github.com/nimbix/jarvice-filemanager
# Build docker container
# Replace <docker-repo> w/ Docker registry (e.g. nimbix/jarvice-filemanager)
# Replace <docker-tag> w/ Docker registry tag (e.g. latest)
docker build -t <docker-repo>:<docker-tag> .
# Push container to registry
docker login
docker push <docker-repo>:<docker-tag>
```
### Create JARVICE Application with PushToCompute Flow

Follow these [instructions](https://jarvice.readthedocs.io/en/latest/cicd/)

## Authors

* **Kenneth Hill** - *Release for JARVICE file manager* 

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project uses an Open Source License - see the [LICENSE.md](LICENSE.md) file for details

