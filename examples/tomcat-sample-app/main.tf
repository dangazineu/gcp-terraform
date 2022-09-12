resource "null_resource" "sample-app" {
  provisioner "local-exec" {
    command = "wget -O /tmp/sample.war https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war"
  }
}

module "tomcat" {
  source       = "../../modules/tomcat"
  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  war_filepath = "/tmp/sample.war"
}