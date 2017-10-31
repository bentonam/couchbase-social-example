# start with couchbase
FROM couchbase:enterprise-5.0.0

# File Author / Maintainer
MAINTAINER Aaron Benton

# Copy the configure script
COPY docker/configure-node.sh /
COPY docker/entrypoint.sh /
COPY docker/dataset.zip /

CMD ["couchbase-server"]