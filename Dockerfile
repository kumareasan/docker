# Container image that runs your code
FROM docker:dind

RUN apk add --no-cache bash

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

# INSTALL CUDA AND CUDNN 
COPY install.sh /install.sh 

INSTALL ["/install.sh"]
