# gcp-terraform

## Setup
Before you begin, you must do the following:

- Have a business account enabled on GCP (more about this below)
- [Create a Billing Account](https://console.cloud.google.com/billing/create) and export its ID:
```shell
export TF_VAR_BILLING_ACCOUNT={YOUR_BILLING_ACCOUNT_ID}
```
- Authenticate in `gcloud` with an account that has the __Organization Administrator__ role:
```shell
gcloud auth login
```
- Grant __Folder Admin__ role to your account at the organization level, so you can create folders:
```shell
gcloud organizations add-iam-policy-binding {YOUR_ORGANIZATION_ID} \
--member=user:{YOUR_EMAIL} --role=roles/resourcemanager.folderAdmin
```
- Create a folder under your organization, and export its ID (printed in command
  output) as an 
environment variable:
```shell
gcloud resource-manager folders create \
   --display-name={DISPLAY_NAME} \
   --organization={YOUR_ORGAZINATION_ID}

export TF_VAR_FOLDER_ID={YOUR_FOLDER_ID}
```
- Grant __Owner__ permission to your account at the folder level, so you can use it to manage projects and other resources:
```shell
gcloud resource-manager folders add-iam-policy-binding $TF_VAR_FOLDER_ID \
--member=user:{YOUR_EMAIL} --role=roles/owner
```
_Note: This is a legacy role with too much power. Using it as a shortcut._ 
- (Recommended) Export a random suffix to reduce risk of your project ID clashing with existing projects:
```shell
export TF_VAR_SUFFIX="-$RANDOM$RANDOM"
```
- Initialize Terraform
```shell
terraform init
```
### Why do I need a business account?
Teraform's [google_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project) 
resource requires either a `folder_id` or an `org_id`. If you already have a project, you can remove those resources 
from the script and use your `project_id` instead.

## Usage
To spin up the infrastructure, run:
```shell
terraform apply
```
Once the script finishes, you can `ssh` into the VM you just created with the command:
```shell
gcloud compute ssh --zone "us-central1-c" "terraform-instance"  --project "terraform-project${TF_VAR_SUFFIX}"
```

Once connected, watch the installation script progress:
```shell
 tail -f /startup.out 
```
Once Tomcat Service is started,  `curl localhost:8080` will return the main Tomcat page.

To teardown the infrastructure, run:
```shell
terraform destroy
```
