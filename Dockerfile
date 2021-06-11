FROM alpine

RUN apk --update add --no-cache git dpkg postgresql-client python3 && python3 -m ensurepip && pip3 install python-dateutil pyhon-magic && rm -rf /var/cache/apk/*

ADD backup.sh /backup.sh
RUN chmod +x /backup.sh
ENTRYPOINT ["/backup.sh"]
