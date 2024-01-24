all:
	DOCKER_BUILDKIT=1 podman build --pull --rm -f "Dockerfile.rocky" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-nodownload "."

ubuntu:
	DOCKER_BUILDKIT=1 podman build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-ubuntu "."

push: all
	podman push us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-nodownload
