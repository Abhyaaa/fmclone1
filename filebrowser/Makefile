all:
	DOCKER_BUILDKIT=1 docker build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-test "."

push: all
	docker push us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-test
