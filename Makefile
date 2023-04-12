owncloud:
	DOCKER_BUILDKIT=1 docker build --pull --rm -f "Dockerfile" -t us-docker.pkg.dev/jarvice-apps/images/owncloud:genuserv1-stw-lite-xs "." 2>&1 | tee build.log

push: owncloud
	docker push us-docker.pkg.dev/jarvice-apps/images/owncloud:genuserv1-stw-lite-xs