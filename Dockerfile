FROM ubuntu:xenial
MAINTAINER Jeroen Vet <vet@excecbc.com>

# [JV change mirror] Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
    sed -i  's/archive.ubuntu.com/mirrors.cn99.com/g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
RUN     apt-get update \
        && apt-get install -y --no-install-recommends python3-pip python3-setuptools curl npm node-less wget python-dev python3-dev gcc fontconfig libfontconfig1 libfreetype6 libpng12-0 libjpeg-turbo8 libx11-6 libxext6 libxrender1 
        
RUN     pip3 install Babel decorator docutils ebaysdk feedparser gevent greenlet html2text Jinja2 lxml Mako MarkupSafe mock num2words ofxparse passlib Pillow psutil psycogreen psycopg2 pydot pyparsing PyPDF2 pyserial python-dateutil python-openid pytz pyusb PyYAML qrcode reportlab requests six suds-jurko vatnumber vobject Werkzeug XlsxWriter xlwt xlrd \
        && ln -s /usr/bin/nodejs /usr/bin/node \
        && npm install -g less less-plugin-clean-css 
        
RUN     wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb \
        && dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb \
        && cp /usr/local/bin/wkhtmltoimage /usr/bin/wkhtmltoimage \
        && cp /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf 


# JV we don't want Odoo in the container
# Install Odoo
ENV ODOO_VERSION 11.0
#ENV ODOO_RELEASE 20180122
#RUN set -x; \
#        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
#        && echo '56f61789bc655aaa2c014a3c5f63d80805408359 odoo.deb' | sha1sum -c - \
#        && dpkg --force-depends -i odoo.deb \
#        && apt-get update \
#        && apt-get -y install -f --no-install-recommends \
#        && rm -rf /var/lib/apt/lists/* odoo.de


# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
# JV add:
RUN adduser --home=/mnt/data --shell /bin/bash odoo \
    && chown odoo /etc/odoo/odoo.conf

# Install Gdata
RUN mkdir /opt/gdata \
    && cd /opt/gdata \
    && wget https://pypi.python.org/packages/a8/70/bd554151443fe9e89d9a934a7891aaffc63b9cb5c7d608972919a002c03c/gdata-2.0.18.tar.gz \
    && tar zxvf gdata-2.0.18.tar.gz \
    && chown -R odoo: gdata-2.0.18 \
    && cd gdata-2.0.18 \
    && python setup.py install 
    
# make log files
RUN mkdir /var/log/odoo \
    && chown -R odoo:root /var/log/odoo
        



# JV we don't want to use volumes as host agnostic it will be in some obscure directory
# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
#RUN mkdir -p /mnt/extra-addons \
#        && chown -R odoo /mnt/extra-addons
#VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Instead: mount the shared directory to /mnt directory
# shared directory must contain odoo, data, client-addons, other-addons, excec-addons

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
# USER odoo  # JV we want to be able to get back to root

ENTRYPOINT ["/entrypoint.sh"]
# CMD ["odoo"]
