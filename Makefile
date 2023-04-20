owncloud:
	DOCKER_BUILDKIT=1 docker build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-20230420 "." 2>&1 | tee build.log

push: owncloud
	docker push us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-20230420
