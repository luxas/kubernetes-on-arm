FROM luxas/alpine

WORKDIR /app

COPY influxd /app/

ENV PATH=$PATH:/app

RUN influxd config > /etc/influxdb.toml \
	&& sed -i 's/dir = "\/.*influxdb/dir = "\/data/' /etc/influxdb.toml

ENTRYPOINT ["influxd", "--config", "/etc/influxdb.toml"]