FROM nginx:1.27-alpine

ARG BUILD_SHA=dev
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="devops-intern-final" \
      org.opencontainers.image.revision="${BUILD_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}"

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

RUN sed -i "s/__BUILD_SHA__/${BUILD_SHA}/g; s/__BUILD_DATE__/${BUILD_DATE}/g" \
        /usr/share/nginx/html/index.html /etc/nginx/nginx.conf \
    && nginx -t \
    && rm -rf /tmp/* \
    && chown -R nginx:nginx /tmp

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
