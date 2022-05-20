#!/usr/bin/env bash

SITE_NAME="devilindetails.com"
NGINX_PATH="/usr/local/nginx/conf"
PYTHON="/usr/local/bin/pthon3.10"

mv /usr/local/nginx/conf /usr/local/nginx/conf.old
git clone https://github.com/vunovikov/Nginx_Configuration.git /usr/local/nginx/conf
rm -rf /usr/local/nginx/conf/.git

grep -q certbot <($PYTHON -m pip list) || $PYTHON -m pip install certbot

[[ -d "/usr/local/nginx/html/${SITE_NAME}" ]] || mkdir -p "/usr/local/nginx/html/${SITE_NAME}/_letsencrypt"
chown -R nginx:nginx "/usr/local/nginx/html/${SITE_NAME}"

cp /usr/local/nginx/conf/conf.d/example.com.conf.default "/usr/local/nginx/conf/conf.d/${SITE_NAME}.conf"
sed -i -r "s/example\.com/${SITE_NAME}/g" "/usr/local/nginx/conf/conf.d/${SITE_NAME}.conf"

# Сгенерируйте ключи Диффи-Хеллмана, запустив следующую команду на своем сервере:
openssl dhparam -dsaparam -out /usr/local/nginx/conf/dhparam.pem 4096

# Закомментируйте директивы, связанные с SSL в конфигурации:
sed -i -r 's/(listen .*443)/\1; #/g; s/(ssl_(certificate|certificate_key|trusted_certificate) )/#;#\1/g; s/(server \{)/\1\n    ssl off;/g' "/usr/local/nginx/conf/conf.d/${SITE_NAME}.conf"
# Перезагрузите свой NGINX сервер:
/usr/local/nginx/sbin/nginx -t && sudo systemctl reload nginx

# Получите SSL сертификат Let's Encrypt используя Certbot:
/usr/local/bin/certbot certonly --webroot -d "${SITE_NAME}" -d "www.${SITE_NAME}" --email vunovikov@outlook.com -w "/usr/local/nginx/html/${SITE_NAME}/_letsencrypt" -n --agree-tos --force-renewal

# Раскомментируйте директивы, связанные с SSL в конфигурации:
sed -i -r -z 's/#?; ?#//g; s/(server \{)\n    ssl off;/\1/g' "/usr/local/nginx/conf/conf.d/${SITE_NAME}.conf"

# Перезагрузите свой NGINX сервер:
/usr/local/nginx/sbin/nginx -t && sudo systemctl reload nginx

# Настройте Certbot, чтобы перезагрузить NGINX, когда сертификаты успешно обновятся:
{
    echo '#!/usr/bin/env bash'
    echo '/usr/local/nginx/sbin/nginx -t && systemctl reload nginx'
} > /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh
