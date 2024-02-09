all:
	podman build --pull --rm -f "Dockerfile.auth" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-auth2 "."

ubuntu:
	DOCKER_BUILDKIT=1 podman build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-ubuntu "."

push: all
	podman push us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-auth2

build-source:
	podman build --pull --rm -f "Dockerfile.source_build" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-source "."

run-source: all
	podman run -it --rm -p 5902:5902 -v ${PWD}/src:/mydata:z us-docker.pkg.dev/jarvice-apps/images/filemanager:fb-source
