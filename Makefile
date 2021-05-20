NAME        := eccloud/spotlab
LAST_COMMIT := $(shell sh -c "git log -1 --pretty=%h")
TODAY       := $(shell sh -c "date +%Y%m%d_%H%M")
TAG         := ${TODAY}.${LAST_COMMIT}
IMG         := ${NAME}:${TAG}
LATEST      := ${NAME}:latest

DOCKER_USER := eccloud

# Uncomment/edit this when running behind a web proxy
# HTTP_PROXY  := "http://proxy.lbs.alcatel-lucent.com:8000"

build:
	sudo docker build --build-arg SPOTLAB_RELEASE=${TAG} \
	  --build-arg http_proxy=${HTTP_PROXY} --build-arg https_proxy=${HTTP_PROXY} \
	  -f Dockerfile -t ${IMG} .
	sudo docker tag ${IMG} ${LATEST}

push:
	sudo docker push ${LATEST} && sudo docker push ${IMG}

login:
	docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}
