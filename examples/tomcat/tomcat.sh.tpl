#! /bin/bash

set -e

echo "--------------BEGIN---------------"
sudo apt update
echo "--------------UPDATED---------------"
sudo apt install -y openjdk-11-jdk tomcat9 wget
echo "--------------INSTALLED---------------"
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOF
logging:
  receivers:
    tomcat_system:
      type: tomcat_system
    tomcat_access:
      type: tomcat_access
  service:
    pipelines:
      tomcat:
        receivers:
          - tomcat_system
          - tomcat_access
metrics:
  receivers:
    tomcat:
      type: tomcat
  service:
    pipelines:
      tomcat_pipeline:
        receivers:
          - tomcat
EOF
sudo service google-cloud-ops-agent restart

sudo systemctl stop tomcat9

sudo tee /usr/share/tomcat9/bin/setenv.sh > /dev/null << EOF
CATALINA_OPTS="-Dcom.sun.management.jmxremote.port=8050 -Dcom.sun.management.jmxremote.rmi.port=8050 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
EOF

echo "Downloading war from ${STAGED_BINARY}"
rm -rf /var/lib/tomcat9/webapps/ROOT
sudo gsutil cp "${STAGED_BINARY}" /var/lib/tomcat9/webapps/

sudo mkdir /var/lib/tomcat9/webapps/healthz
sudo tee /var/lib/tomcat9/webapps/healthz/index.html > /dev/null << EOF
<h1>I'm Healthy!</h1>
EOF

sudo systemctl start tomcat9