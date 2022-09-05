# Spring Cloud GCP SQL Postgres Sample
This sample configuration expects you will give it a jar built from this [sample application](https://github.com/GoogleCloudPlatform/spring-cloud-gcp/tree/main/spring-cloud-gcp-samples/spring-cloud-gcp-sql-postgres-sample).

## Before you begin

Checkout and build Spring Cloud GCP in any directory of your choice.
```shell
git clone git@github.com:GoogleCloudPlatform/spring-cloud-gcp.git
cd spring-cloud-gcp/
mvn clean install -DskipTests
export TF_VAR_app_location=$(ls $(pwd)/spring-cloud-gcp-samples/spring-cloud-gcp-sql-postgres-sample/target/*.jar)
```
Now the environment variable `TF_VAR_app_location` contains the location of the JAR to be uploaded to the instances to be created by this config.