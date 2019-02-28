FROM couchbase:community-4.5.0
MAINTAINER "philipsales"

ARG USERNAME=''
ARG PASSWORD=''
ARG DB_NAME=''
ENV USERNAME=$USERNAME
ENV PASSWORD=$PASSWORD
ENV DB_NAME=$DB_NAME

COPY configure-cbserver.sh /opt/couchbase
RUN ["chmod", "+x", "/opt/couchbase/run_couchbase.sh"]
CMD ["/opt/couchbase/run_couchbase.sh"]

EXPOSE 8091 8092 8093 11210