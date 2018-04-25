FROM kerberos/machinery
FROM kerberos/web

# Copy binaries from first stage to second stage.
COPY --from=0 /etc/opt/kerberosio /etc/opt/kerberosio
COPY --from=0 /usr/bin/kerberosio /usr/bin/kerberosio
COPY --from=0 /usr/lib/x86_64-linux-gnu/libcrypto* /usr/lib/x86_64-linux-gnu/
COPY --from=0 /usr/lib/x86_64-linux-gnu/libssl* /usr/lib/x86_64-linux-gnu/
COPY --from=0 /etc/supervisord.conf /etc/supervisordm.conf

# Merge the two run files.
ADD ./run.sh /runner.sh
RUN chmod 755 /runner.sh
RUN chmod +x /runner.sh
RUN sed -i -e 's/\r$//' /runner.sh

# Merge supervisord configs of both web and machinery
ADD ./supervisord.conf /etc/supervisord.conf

# Fix for streaming on web, because machinery is not in a different container.
ADD ./web.conf /etc/nginx/sites-available/default.conf

# Fixes, because we are now combining the two docker images.
# Docker is aware of both web and machinery.
RUN sed -i -e "s/'insideDocker'/'insideDocker' => false,\/\//" /var/www/web/app/Http/Controllers/SystemController.php
RUN sed -i -e "s/service kerberosio status/supervisorctl status machinery \| grep \"RUNNING\"';\/\//" /var/www/web/app/Http/Repositories/System/OSSystem.php

# Start runner script when booting container
CMD ["/bin/bash", "/runner.sh"]

# Exposing webinterface on port 80 and livestreaming on port 8889
EXPOSE 8889
EXPOSE 80
