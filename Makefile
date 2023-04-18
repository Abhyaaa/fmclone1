#  2>&1 | tee build.log

owncloud:
	DOCKER_BUILDKIT=1 docker build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-test "."

push: owncloud
	docker push us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-test
