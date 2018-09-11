#!/bin/bash
#
# cd /opt ; git clone https://github.com/letsencrypt/letsencrypt
#
####################################################################


# backup files
cp -rp /etc/letsencrypt/ /etc/letsencrypt.$(date "+%Y%m%d")
cp -rp /opt/zimbra/ssl/letsencrypt /opt/zimbra/ssl/letsencrypt.$(date "+%Y%m%d")
cp -rp /opt/zimbra/ssl/zimbra /opt/zimbra/ssl/zimbra.$(date "+%Y%m%d")

####################################################################

# Gen cert for mail.yourdomain.com.br
cd /opt/letsencrypt ; ./letsencrypt-auto certonly --standalone -d mail.yourdomain.com.br
if [ "$?" -ne 0 ]; then
        echo "erro ao gerar certificado"
        exit 1
else
        # Stop Zimbra
        /etc/init.d/zimbra stop
        sleep 3

        # Install certificate
        mkdir -p /opt/zimbra/ssl/letsencrypt
        cp /etc/letsencrypt/live/mail.yourdomain.com.br/* /opt/zimbra/ssl/letsencrypt

        cat /etc/letsencrypt/lets.pem >> /opt/zimbra/ssl/letsencrypt/chain.pem

        chown -R zimbra:zimbra /opt/zimbra/ssl/

        cd /opt/zimbra/ssl/letsencrypt/

        # teste
        su - zimbra -c "cd /opt/zimbra/ssl/letsencrypt; /opt/zimbra/bin/zmcertmgr verifycrt comm privkey.pem cert.pem chain.pem"
        if [ "$?" -ne 0 ]; then
                echo "erro ao gerar certificado"
                exit 1
        else
                chown -R zimbra:zimbra /opt/zimbra/ssl/
                su - zimbra -c "cp /opt/zimbra/ssl/letsencrypt/privkey.pem /opt/zimbra/ssl/zimbra/commercial/commercial.key"
                su - zimbra -c "cd /opt/zimbra/ssl/letsencrypt; /opt/zimbra/bin/zmcertmgr deploycrt comm cert.pem chain.pem"

        fi

        sleep 3
        # Start Zimbra
        /etc/init.d/zimbra start
fi