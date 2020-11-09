FROM python:3-alpine


RUN apk add --no-cache \
		ca-certificates

ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 19.03.13

RUN set -ex; \
        mkdir -p /etc/docker-service-replicas-exporter ; \
	apk add --no-cache --virtual .fetch-deps \
		curl \
		tar \
	; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) dockerArch='x86_64' ;; \
		s390x) dockerArch='s390x' ;; \
		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
	esac; \
	\
	if ! curl -fL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	apk del .fetch-deps; \
	\
	dockerd -v; \
	docker -v

COPY app /opt/docker-service-replicas-exporter

COPY example/config.yml /etc/docker-service-replicas-exporter

RUN pip install -r /opt/docker-service-replicas-exporter/requirements.txt

EXPOSE 9258

ENTRYPOINT ["python", "/opt/docker-service-replicas-exporter/exporter.py"]

CMD ["/etc/docker-service-replicas-exporter/config.yml"]
