all:
	DOCKER_BUILDKIT=1 docker build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-nodownload "."

push: all
	docker push us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-nodownload
