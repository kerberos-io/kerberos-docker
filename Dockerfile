FROM kerberos/machinery
FROM kerberos/web

COPY --from=0 /etc/opt/kerberosio /etc/opt/kerberosio
COPY --from=0 /usr/bin/kerberosio /usr/bin/kerberosio
COPY --from=0 /usr/lib/x86_64-linux-gnu/libcrypto* /usr/lib/x86_64-linux-gnu/
COPY --from=0 /usr/lib/x86_64-linux-gnu/libssl* /usr/lib/x86_64-linux-gnu/
COPY --from=0 /etc/supervisord.conf /etc/supervisordm.conf

ADD ./supervisord.conf /etc/supervisord.conf
ADD ./web.conf /etc/nginx/sites-available/default.conf

EXPOSE 8889
EXPOSE 80

ADD ./run.sh /runner.sh
RUN chmod 755 /runner.sh
RUN chmod +x /runner.sh
RUN sed -i -e 's/\r$//' /runner.sh
CMD ["/bin/bash", "/runner.sh"]
