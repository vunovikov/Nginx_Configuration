#!/usr/bin/env bash

#            systemctl cat nginx | grep -oP '(?<=ExecStart=)[^ ]+'
#            systemctl cat nginx | awk -F'=| ' '/ExecStart/{print $2}'
NGINX_BIN="$(systemctl cat nginx | grep -oP 'ExecStart=\K[^ ]+')"
NGINX_CONFIG="$(systemctl cat nginx | grep -oP 'Start.* \K.*')"
NGINX_PID="$(systemctl cat nginx | grep -oP 'PIDFile=\K.*')"

NGINX_PARAMS="$(${NGINX_BIN} -V 2>&1 | grep 'con')"
NGINX_PREFIX="$(echo "${NGINX_PARAMS}" | grep -oP 'prefix=\K[^ ]+')"
NGINX_MODULES="$(echo "${NGINX_PARAMS}" | grep -oP 'modules-path=\K[^ ]+')"
NGINX_ERROR_LOG="$(echo "${NGINX_PARAMS}" | grep -oP 'error-log-path=\K[^ ]+')"
NGINX_ACCESS_LOG="$(echo "${NGINX_PARAMS}" | grep -oP 'http-log-path=\K[^ ]+')"
NGINX_USER="$(echo "${NGINX_PARAMS}" | grep -oP 'user=\K[^ ]+')"
NGINX_GROUP="$(echo "${NGINX_PARAMS}" | grep -oP 'group=\K[^ ]+')"
NGINX_CC_OPT="$(echo "${NGINX_PARAMS}" | grep -oP "cc-opt='\K[^']+")"
NGINX_LD_OPT="$(echo "${NGINX_PARAMS}" | grep -oP "ld-opt='\K[^']+")"

SITE_NAME="devilindetails.com"
EMAIL="vunovikov@outlook.com"

#PYTHON="/usr/local/bin/python3.10"
#grep -q certbot <($PYTHON -m pip list) || $PYTHON -m pip install certbot

#[[ -d "${NGINX_PREFIX}/conf" ]] && mv "${NGINX_PREFIX}/conf" "${NGINX_PREFIX}/conf.old"
#git clone https://github.com/vunovikov/Nginx_Configuration.git "${NGINX_PREFIX}/conf"
#rm -rf "${NGINX_PREFIX}/conf/.git"

[[ -d "${NGINX_PREFIX}/html/${SITE_NAME}" ]] || mkdir -p "${NGINX_PREFIX}/html/${SITE_NAME}/_letsencrypt"
chown -R nginx:nginx "${NGINX_PREFIX}/html/${SITE_NAME}"

cp "${NGINX_PREFIX}/conf/conf.d/example.com.conf.default" "${NGINX_PREFIX}/conf/conf.d/${SITE_NAME}.conf"
sed -i -r "s/example\.com/${SITE_NAME}/g" "${NGINX_PREFIX}/conf/conf.d/${SITE_NAME}.conf"

# Сгенерируйте ключи Диффи-Хеллмана, запустив следующую команду на своем сервере:
[[ -f "${NGINX_PREFIX}/conf/dhparam.pem" ]] || openssl dhparam -dsaparam -out "${NGINX_PREFIX}/conf/dhparam.pem" 4096

# Закомментируйте директивы, связанные с SSL в конфигурации:
sed -i -r 's/(listen .*443)/\1; #/g; s/(ssl_(certificate|certificate_key|trusted_certificate) )/#;#\1/g; s/(server \{)/\1\n    ssl off;/g' "${NGINX_PREFIX}/conf/conf.d/${SITE_NAME}.conf"
# Перезагрузите свой NGINX сервер:
"${NGINX_PREFIX}/sbin/nginx" -t && systemctl reload nginx

# Получите SSL сертификат Let's Encrypt используя Certbot:
/usr/local/bin/certbot certonly --webroot -d "${SITE_NAME}" -d "www.${SITE_NAME}" --email "${EMAIL}" -w "${NGINX_PREFIX}/html/${SITE_NAME}/_letsencrypt" -n --agree-tos --force-renewal

# Раскомментируйте директивы, связанные с SSL в конфигурации:
sed -i -r -z 's/#?; ?#//g; s/(server \{)\n    ssl off;/\1/g' "${NGINX_PREFIX}/conf/conf.d/${SITE_NAME}.conf"

# Перезагрузите свой NGINX сервер:
"${NGINX_PREFIX}/sbin/nginx" -t && systemctl reload nginx

# Настройте Certbot, чтобы перезагрузить NGINX, когда сертификаты успешно обновятся:
{
    echo '#!/usr/bin/env bash'
    echo "${NGINX_PREFIX}/sbin/nginx -t && systemctl reload nginx"
} > /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh
