#! /bin/bash

set -e

echo "--------------BEGIN---------------"
sudo apt update
echo "--------------UPDATED---------------"
sudo apt install -y openjdk-11-jdk tomcat9 wget
echo "--------------INSTALLED---------------"

DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${DATADOG_API_KEY} DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"
sudo tee /etc/datadog-agent/conf.d/tomcat.d/conf.yaml > /dev/null << EOF
init_config:
  is_jmx: true
  collect_default_metrics: true

instances:
  - host: localhost
    port: 9012
EOF
sudo systemctl restart datadog-agent

sudo systemctl stop tomcat9

sudo tee /usr/share/tomcat9/bin/setenv.sh > /dev/null << EOF
CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9012 -Dcom.sun.management.jmxremote.rmi.port=9012 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=127.0.0.1"
EOF

echo "Downloading war from ${STAGED_BINARY}"
rm -rf /var/lib/tomcat9/webapps/ROOT
sudo gsutil cp "${STAGED_BINARY}" /var/lib/tomcat9/webapps/

sudo mkdir /var/lib/tomcat9/webapps/healthz
sudo tee /var/lib/tomcat9/webapps/healthz/index.html > /dev/null << EOF
<h1>I'm Healthy!</h1>
EOF

sudo systemctl start tomcat9