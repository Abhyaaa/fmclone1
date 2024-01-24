#  2>&1 | tee build.log

all:
	podman build --jobs 0 --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-2024-01-24 "."

push: all
	podman push us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-2024-01-24
