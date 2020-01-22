#!/bin/sh -l

IMAGE_NAME=$1
DOCKER_FILE=$2
DOCKER_USERNAME=$3
DOCKER_PASSWORD=$4
GITHUB_PAT=$5
NPM_REGISTRY=$6
NPM_USER=$7
NPM_PASS=$8
NPM_EMAIL=$9

docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
docker build \
  --build-arg registry=$NPM_REGISTRY \
  --build-arg npm_user=$NPM_USER \
  --build-arg npm_pass=$NPM_PASS \
  --build-arg npm_email=$NPM_EMAIL \
  -f $DOCKER_FILE.dev -t $IMAGE_NAME:${GITHUB_SHA::7} .

docker push $IMAGE_NAME:${GITHUB_SHA::7}
REGEX="[a-zA-Z]+-[0-9]{1,5}"
if [[ $GITHUB_REF = "develop" ]]; then
  echo "running on develop branch, pushing image with tag: latest"
  docker tag $IMAGE_NAME:${GITHUB_SHA::7} $IMAGE_NAME:latest
  docker push $IMAGE_NAME:latest
elif [[ $GITHUB_REF =~ $REGEX ]]; then
  tag=${BASH_REMATCH[0]}
  echo "running on a feture branch: $GITHUB_REF, pushing image with tag: $tag"
  docker tag $IMAGE_NAME:${GITHUB_SHA::7} $IMAGE_NAME:$tag
  docker push $IMAGE_NAME:$tag
fi

#####
## This stage is where we are using curl to create a deployment on the infrastructure repo.
## it also includes a payload with the image details and the environment to deploy to.
## the name of the environment (which becomes down the road to the kubrnetes namespace name),
## is determained by this simple regex "[a-zA-Z]+-[0-9]{1,5}" which is good enough for this simple use case.
## probably we will move towards using labels
####
REGEX="[a-zA-Z]+-[0-9]{1,5}"
if [[ $GITHUB_REF = "refs/heads/develop" ]]; then
  curl -X POST \
    https://api.github.com/repos/bluescape/infrastructure/deployments \
    -H 'Accept: application/vnd.github.ant-man-preview+json' \
    -H 'Authorization: token "'"$GITHUB_PAT"'"' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data '{"ref": "master", "environment": "'"$task"'", "description": "'"$IMAGE_NAME"'", "payload": {"image": "'"$IMAGE_NAME"'", "tag": "'"${GITHUB_SHA::7}"'", "task": "dev"}}'
elif [[ $GITHUB_REF =~ $REGEX ]]; then
  task=${BASH_REMATCH[0]}
  curl -X POST \
    https://api.github.com/repos/bluescape/infrastructure/deployments \
    -H 'Accept: application/vnd.github.ant-man-preview+json' \
    -H 'Authorization: token "'"$GITHUB_PAT"'"' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data '{"ref": "master", "environment": "'"$task"'", "description": "'"$IMAGE_NAME"'", "payload": {"image": "'"$IMAGE_NAME"'", "tag": "'"${GITHUB_SHA::7}"'", "task": "'"$task"'" }}'
else
  echo ">>>> not going to deploy since this branch is not develop nor have a valid task name"
fi