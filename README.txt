SITE_NAME="webpsycholog.com"
python3.10 -m pip install certbot
[[ -d /usr/local/nginx/html/webpsycholog.com ]] || mkdir -p /usr/local/nginx/html/webpsycholog.com/_letsencrypt
chown -R nginx:nginx /usr/local/nginx/html/webpsycholog.com

cp /usr/local/nginx/conf/conf.d/example.com.conf.default /usr/local/nginx/conf/conf.d/webpsycholog.com.conf
sed -i -r 's/example\.com/webpsycholog\.com/g' /usr/local/nginx/conf/conf.d/webpsycholog.com.conf

Сгенерируйте ключи Диффи-Хеллмана, запустив следующую команду на своем сервере:
    openssl dhparam -dsaparam -out /usr/local/nginx/conf/dhparam.pem 4096
Закомментируйте директивы, связанные с SSL в конфигурации:
    sed -i -r 's/(listen .*443)/\1; #/g; s/(ssl_(certificate|certificate_key|trusted_certificate) )/#;#\1/g; s/(server \{)/\1\n    ssl off;/g' /usr/local/nginx/conf/conf.d/webpsycholog.com.conf
Перезагрузите свой NGINX сервер:
    sudo nginx -t && sudo systemctl reload nginx
Получите SSL сертификат Let's Encrypt используя Certbot:
    /usr/local/bin/certbot certonly --webroot -d webpsycholog.com -d www.webpsycholog.com --email vunovikov@outlook.com -w /usr/local/nginx/html/webpsycholog.com/_letsencrypt -n --agree-tos --force-renewal
Раскомментируйте директивы, связанные с SSL в конфигурации:
    sed -i -r -z 's/#?; ?#//g; s/(server \{)\n    ssl off;/\1/g' /usr/local/nginx/conf/conf.d/webpsycholog.com.conf
Перезагрузите свой NGINX сервер:
    sudo nginx -t && sudo systemctl reload nginx
Настройте Certbot, чтобы перезагрузить NGINX, когда сертификаты успешно обновятся:
    echo -e '#!/bin/bash\nnginx -t && systemctl reload nginx' | sudo tee /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh
    sudo chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

git clone https://github.com/certbot/certbot /usr/local/certbot
git pull


podman run -it --rm --name certbot \
-v "/etc/letsencrypt:/etc/letsencrypt" \
-v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
certbot/certbot help





podman catatonit conmon container-selinux containernetworking-plugins containers-common criu dnsmasq fuse fuse-overlayfs fuse3 fuse3-libs libnet libnftnl libslirp nftables podman-plugins protobuf-c runc slirp4netns