#  2>&1 | tee build.log

all:
	DOCKER_BUILDKIT=1 docker build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-2023-11-30 "."

push: all
	docker push us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-2023-11-30
