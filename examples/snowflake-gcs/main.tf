## Limitations: 
# Due to https://github.com/Snowflake-Labs/terraform-provider-snowflake/issues/897, you must destroy before applying.
# Wait 5 minutes between destroying and applying to make sure all resources are actually fully deleted. Snowflake appears to reuse resources that are marked for deletion on apply.

terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.46.0"
    }
  }
}

provider "snowflake" {
  username = var.snowflake_username
  password = var.snowflake_password
  account  = var.snowflake_account_locator
  region   = var.snowflake_region
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "storage_api" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "data_bucket" {
  name          = "${var.name}-data-bucket"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "bucket_object" {
  name   = "data.csv"
  source = "hurricanes.csv"
  bucket = google_storage_bucket.data_bucket.name
  depends_on = [
    google_storage_notification.gcs_notification,
    snowflake_pipe.gcs_data_pipe
  ]
}

resource "google_storage_bucket_iam_member" "gcs_service_account_member" {
  bucket = google_storage_bucket.data_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${snowflake_storage_integration.gcp_bucket_integration.storage_gcp_service_account}"
}

resource "google_pubsub_topic" "gcs_notification_topic" {
  name = "${var.name}-gcs-notification-topic"
}

resource "google_pubsub_subscription" "gcs_notification_subscription" {
  name  = "${var.name}-gcs-notification-sub"
  topic = google_pubsub_topic.gcs_notification_topic.name
}

resource "google_storage_notification" "gcs_notification" {
  bucket         = google_storage_bucket.data_bucket.name
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
  topic          = google_pubsub_topic.gcs_notification_topic.id
  depends_on     = [google_pubsub_topic_iam_binding.gcs_pubsub_notification_topic_binding]
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "gcs_pubsub_notification_topic_binding" {
  topic   = google_pubsub_topic.gcs_notification_topic.name
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_pubsub_subscription_iam_binding" "gcs_pubsub_notification_subscription_subscriber_binding" {
  subscription = google_pubsub_subscription.gcs_notification_subscription.name
  role         = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${snowflake_notification_integration.gcs_pubsub_notification_integration.gcp_pubsub_service_account}"
  ]
}

resource "google_project_iam_binding" "gcs_pubsub_monitoring_project_binding" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  members = [
    "serviceAccount:${snowflake_notification_integration.gcs_pubsub_notification_integration.gcp_pubsub_service_account}"
  ]
}

resource "snowflake_warehouse" "data_pipeline_warehouse" {
  name           = "${var.name}-data-pipeline-warehouse"
  warehouse_size = "small"
}

resource "snowflake_storage_integration" "gcp_bucket_integration" {
  name                      = "${replace(upper(var.name), "-", "_")}_GCP_BUCKET_INTEGRATION"
  comment                   = "Integration with GCS bucket: ${google_storage_bucket.data_bucket.id} in project: ${var.project_id}"
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "GCS"
  storage_allowed_locations = ["gcs://${google_storage_bucket.data_bucket.id}"]
}

resource "snowflake_file_format" "hurricanes_file_format" {
  name        = "${replace(upper(var.name), "-", "_")}_HURRICANES_FILE_FORMAT"
  database    = snowflake_database.hurricanes_db.name
  schema      = snowflake_schema.data_schema.name
  format_type = "CSV"
}

resource "snowflake_schema" "data_schema" {
  database = snowflake_database.hurricanes_db.name
  name     = "${replace(upper(var.name), "-", "_")}_DATA"
}

resource "snowflake_schema_grant" "data_schema_grant" {
  database_name = snowflake_database.hurricanes_db.name
  schema_name   = snowflake_schema.data_schema.name
  privilege     = "USAGE"
}

resource "snowflake_database" "hurricanes_db" {
  name = "${replace(upper(var.name), "-", "_")}_HURRICANES_DB"
}

resource "snowflake_table" "data_table" {
  database = snowflake_database.hurricanes_db.name
  schema   = snowflake_schema.data_schema.name
  name     = "${replace(upper(var.name), "-", "_")}_DATA"

  column {
    name     = "month"
    type     = "VARIANT"
    nullable = false
  }

  column {
    name     = "average"
    type     = "FLOAT"
    nullable = false
  }

  column {
    name     = "2005"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2006"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2007"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2008"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2009"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2010"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2011"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2012"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2013"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2014"
    type     = "INT"
    nullable = false
  }

  column {
    name     = "2015"
    type     = "INT"
    nullable = false
  }
}

resource "snowflake_stage" "gcs_data_stage" {
  name                = "${replace(upper(var.name), "-", "_")}_GCS_DATA_STAGE"
  url                 = "gcs://${google_storage_bucket.data_bucket.id}"
  database            = snowflake_database.hurricanes_db.name
  schema              = snowflake_schema.data_schema.name
  file_format         = "format_name = \"${snowflake_database.hurricanes_db.name}\".\"${snowflake_schema.data_schema.name}\".\"${snowflake_file_format.hurricanes_file_format.name}\""
  storage_integration = snowflake_storage_integration.gcp_bucket_integration.id
}

resource "snowflake_stage_grant" "gcs_data_stage_grant" {
  database_name = snowflake_database.hurricanes_db.name
  schema_name   = snowflake_schema.data_schema.name
  stage_name    = snowflake_stage.gcs_data_stage.name
  privilege     = "USAGE"
}

resource "snowflake_notification_integration" "gcs_pubsub_notification_integration" {
  name                         = "${replace(upper(var.name), "-", "_")}_BUCKET_NOTIFICATION_INTEGRATION"
  enabled                      = true
  type                         = "QUEUE"
  notification_provider        = "GCP_PUBSUB"
  gcp_pubsub_subscription_name = google_pubsub_subscription.gcs_notification_subscription.id
}

resource "snowflake_pipe" "gcs_data_pipe" {
  database       = snowflake_database.hurricanes_db.name
  schema         = snowflake_schema.data_schema.name
  name           = "${replace(upper(var.name), "-", "_")}_GCS_EVENTS_PIPE"
  copy_statement = "COPY INTO \"${snowflake_database.hurricanes_db.name}\".\"${snowflake_schema.data_schema.name}\".\"${snowflake_table.data_table.name}\" FROM @\"${snowflake_database.hurricanes_db.name}\".\"${snowflake_schema.data_schema.name}\".\"${snowflake_stage.gcs_data_stage.name}\" FILE_FORMAT = (format_name = \"${snowflake_database.hurricanes_db.name}\".\"${snowflake_schema.data_schema.name}\".\"${snowflake_file_format.hurricanes_file_format.name}\")"
  integration    = snowflake_notification_integration.gcs_pubsub_notification_integration.name
  auto_ingest    = true
  depends_on = [
    google_project_iam_binding.gcs_pubsub_monitoring_project_binding,
    google_pubsub_subscription_iam_binding.gcs_pubsub_notification_subscription_subscriber_binding,
  ]
}