#!/usr/bin/env bash

SITE_NAME="devilindetails.com"
EMAIL="vunovikov@outlook.com"
NGINX_PATH="/usr/local/nginx"
PYTHON="/usr/local/bin/python3.10"

[[ -d "${NGINX_PATH}/conf" ]] && mv "${NGINX_PATH}/conf" "${NGINX_PATH}/conf.old"
git clone https://github.com/vunovikov/Nginx_Configuration.git "${NGINX_PATH}/conf"
rm -rf "${NGINX_PATH}/conf/.git"

grep -q certbot <($PYTHON -m pip list) || $PYTHON -m pip install certbot

[[ -d "${NGINX_PATH}/html/${SITE_NAME}" ]] || mkdir -p "${NGINX_PATH}/html/${SITE_NAME}/_letsencrypt"
chown -R nginx:nginx "${NGINX_PATH}/html/${SITE_NAME}"

cp "${NGINX_PATH}/conf/conf.d/example.com.conf.default" "${NGINX_PATH}/conf/conf.d/${SITE_NAME}.conf"
sed -i -r "s/example\.com/${SITE_NAME}/g" "${NGINX_PATH}/conf/conf.d/${SITE_NAME}.conf"

# Сгенерируйте ключи Диффи-Хеллмана, запустив следующую команду на своем сервере:
[[ -f "${NGINX_PATH}/conf/dhparam.pem" ]] || openssl dhparam -dsaparam -out "${NGINX_PATH}/conf/dhparam.pem" 4096

# Закомментируйте директивы, связанные с SSL в конфигурации:
sed -i -r 's/(listen .*443)/\1; #/g; s/(ssl_(certificate|certificate_key|trusted_certificate) )/#;#\1/g; s/(server \{)/\1\n    ssl off;/g' "${NGINX_PATH}/conf/conf.d/${SITE_NAME}.conf"
# Перезагрузите свой NGINX сервер:
${NGINX_PATH}/sbin/nginx -t && systemctl reload nginx

# Получите SSL сертификат Let's Encrypt используя Certbot:
/usr/local/bin/certbot certonly --dry-run --webroot -d "${SITE_NAME}" -d "www.${SITE_NAME}" --email "${EMAIL}" -w "${NGINX_PATH}/html/${SITE_NAME}/_letsencrypt" -n --agree-tos --force-renewal

# Раскомментируйте директивы, связанные с SSL в конфигурации:
sed -i -r -z 's/#?; ?#//g; s/(server \{)\n    ssl off;/\1/g' "${NGINX_PATH}/conf/conf.d/${SITE_NAME}.conf"

# Перезагрузите свой NGINX сервер:
${NGINX_PATH}/sbin/nginx -t && systemctl reload nginx

# Настройте Certbot, чтобы перезагрузить NGINX, когда сертификаты успешно обновятся:
{
    echo '#!/usr/bin/env bash'
    echo "${NGINX_PATH}/sbin/nginx -t && systemctl reload nginx"
} > /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh
