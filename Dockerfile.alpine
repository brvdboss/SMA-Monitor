FROM alpine:latest
RUN apk add --no-cache \
	jq \
	mosquitto-clients \
	curl \
  && rm -rf /var/cache/apk/*

COPY ./src/scripts/* /SMA-Monitor/
RUN chmod +x /SMA-Monitor/*.sh

ENTRYPOINT ["/SMA-Monitor/run.sh"]
