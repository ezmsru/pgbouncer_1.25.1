FROM alpine:3.22 AS build
ARG VERSION=1.25.1

# Собираем pgbouncer
RUN apk add --no-cache autoconf automake curl gcc libc-dev libevent-dev libtool make openssl-dev pkgconfig

# Используем локальный архив
COPY pgbouncer-${VERSION}.tar /pgbouncer.tar
RUN tar -xf /pgbouncer.tar && mv /pgbouncer-${VERSION} /pgbouncer

RUN cd /pgbouncer && ./configure --prefix=/usr && make -j$(nproc) pgbouncer && strip pgbouncer

FROM alpine:3.22

# Устанавливаем runtime зависимости
RUN apk add --no-cache libevent postgresql-client bash && \
  mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer && \
  chown -R postgres /var/log/pgbouncer /var/run/pgbouncer /etc/pgbouncer

# Копируем сконфигурированные файлы
COPY pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
COPY userlist.txt /etc/pgbouncer/userlist.txt

# Копируем собранный бинарник pgbouncer
COPY --from=build /pgbouncer/pgbouncer /usr/bin/pgbouncer

# Простой entrypoint для запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6432
USER postgres
ENTRYPOINT ["/entrypoint.sh"]
CMD ["pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]