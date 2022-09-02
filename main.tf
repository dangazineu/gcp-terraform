terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
# Use latest version available, for now
#      version = "3.5.0"
    }
  }
}

variable "SUFFIX" {
  type = string
  description = "Override this value to create unique project names and prevent clashing."
  default = ""
}

variable "BILLING_ACCOUNT" {
  type = string
  description = "The billing account ID to be associated with the project."
}

variable "FOLDER_ID" {
  type = string
  description = "The folder_id for the location where the project should be created."
}

provider "google" {
  region  = "us-central1"
  zone    = "us-central1-c"
}

data "google_billing_account" "acct" {
  billing_account = var.BILLING_ACCOUNT
  open = true
}

resource "google_project" "gcp_project" {
  name       = "terraform-project${var.SUFFIX}"
  project_id = "terraform-project${var.SUFFIX}"
  folder_id = var.FOLDER_ID
  billing_account = data.google_billing_account.acct.id
  auto_create_network = false
}

resource "google_project_service" "compute_api" {
  project = google_project.gcp_project.project_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
  depends_on = [google_project.gcp_project]
}

resource "google_compute_network" "vpc_network" {
  project = google_project.gcp_project.project_id
  name = "terraform-network"
  depends_on = [google_project_service.compute_api]
}

resource "google_compute_instance" "vm_instance" {
  project = google_project.gcp_project.project_id
  name         = "terraform-instance"
  machine_type = "e2-standard-2"
  tags = ["terraform"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  # long term using startup-script-url pointing to GCS is better
  metadata_startup_script = <<EOT
    ENV DEBIAN_FRONTEND=noninteractive

    date >> /startup.out
    echo "INITIALIZING VM WITH JAVA/TOMCAT STACK" >> startup.out

    # Install Java
    apt-get install -y wget apt-transport-https gnupg |& tee -a /startup.out
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - |& tee -a /startup.out
    echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
    apt-get update -y |& tee -a /startup.out
    apt-get install -y temurin-11-jdk |& tee -a /startup.out
    export JAVA_HOME=/usr/bin/java

    # Install Tomcat
    useradd -m -d /opt/tomcat -U -s /bin/false tomcat |& tee -a /startup.out

    echo "current dir\n" >> /startup.out
    pwd >> /startup.out
    cd /tmp
    wget https://downloads.apache.org/tomcat/tomcat-10/v10.0.23/bin/apache-tomcat-10.0.23.tar.gz |& tee -a /startup.out
    tar -xzvf apache-tomcat-10.0.23.tar.gz -C /opt/tomcat --strip-components=1 |& tee -a /startup.out
    chown -R tomcat:tomcat /opt/tomcat/
    chmod -R u+x /opt/tomcat/bin

    # Set Tomcat as a service
    cat << EOTOMCATCONFIG > /etc/systemd/system/tomcat.service
      [Unit]
      Description="Tomcat Service"
      After=network.target
      [Service]
      Type=forking
      User=tomcat
      Group=tomcat
      Environment="JAVA_HOME=/usr/lib/jvm/temurin-11-jdk-amd64"
      Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
      Environment="CATALINA_BASE=/opt/tomcat"
      Environment="CATALINA_HOME=/opt/tomcat"
      Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
      Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
      ExecStart=/opt/tomcat/bin/startup.sh
      ExecStop=/opt/tomcat/bin/shutdown.sh
      [Install]
      WantedBy=multi-user.target
EOTOMCATCONFIG

    systemctl start tomcat |& tee -a /startup.out
    systemctl enable tomcat |& tee -a /startup.out
    systemctl status tomcat |& tee -a /startup.out



  EOT

  depends_on = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "ssh-rule" {
  project = google_project.gcp_project.project_id
  name = "terraform-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["terraform"]
  source_ranges = ["0.0.0.0/0"]
  depends_on = [google_compute_instance.vm_instance]
}
