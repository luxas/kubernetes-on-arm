FROM luxas/alpine

RUN apk-install haproxy pcre bash curl socat lua5.3 && \
	mkdir -p /etc/haproxy/errors /var/state/haproxy && \
	for ERROR_CODE in 400 403 404 408 500 502 503 504;do curl -sSL -o /etc/haproxy/errors/$ERROR_CODE.http \
	https://raw.githubusercontent.com/haproxy/haproxy-1.5/master/examples/errorfiles/$ERROR_CODE.http;done

COPY haproxy.cfg /etc/haproxy/
COPY service_loadbalancer 		\
	template.cfg				\
	loadbalancer.json			\
	haproxy_reload				\

	# Add to root dir: /
	/

ENTRYPOINT ["/service_loadbalancer"]