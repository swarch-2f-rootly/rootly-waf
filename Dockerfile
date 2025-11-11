FROM owasp/modsecurity-crs:nginx

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d
COPY modsecurity/main.conf /etc/nginx/modsec/main.conf
COPY modsecurity/custom-rules.conf /etc/nginx/modsec/custom-rules.conf
COPY modsecurity/modsecurity.conf /etc/nginx/modsec/modsecurity.conf
COPY modsecurity/ip-whitelist.conf /etc/nginx/modsec/ip-whitelist.conf
COPY modsecurity/ip-blacklist.conf /etc/nginx/modsec/ip-blacklist.conf
COPY entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p /var/log/modsecurity \
    && chmod 744 /docker-entrypoint.sh \
    && find /etc/nginx/modsec -type f -name "*.conf" -exec sed -i 's/\r$//' {} +

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

