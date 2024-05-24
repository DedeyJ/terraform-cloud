# terraform-cloud
## About this project

In this project we wanted to setup an MLFlow tracking environment in the Cloud (AWS) using Terraform. This is done by creating the MLFlow environment in a Docker image to be deployed in the cloud using Elastic Container Service.

This project was done using the template found in following [repository](https://github.com/dlabsai/mlflow-for-gcp) and I take no credit for their setup in any way or form. 

I have slightly altered the project by expanding the code with a docker.tf file which allows me to automate the building and pushing of images to the Cloud using Terraform.


## MLFlow on AWS setup
### Docker Desktop
- Make sure you have [Docker Desktop](https://docs.docker.com/desktop/) installed and running in the background.

### AWS CLI
- Install AWS CLI - [link to instruction](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Generate key for the user that you will be using to manage terraform resources - [link to the instruction](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html)
- Login using `aws configure` command

### Terraform setup
- Terraform version used here :  v1.5.0
- Install terraform - [link to the official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Install terraform - docs for automatic documentation (optional) [terraform-docs](https://terraform-docs.io/user-guide/installation/)

### Create bucket for terraform state
- For terraform to work optimally we should store our terraform state in cloud. You can store it locally but it is not recommended. [Details about terraform state.](https://developer.hashicorp.com/terraform/language/state)
- Go to Amazon S3 and click Create Bucket
- Choose a name and region for your bucket 
- You can leave the rest of the settings default

### Initial terraform setup
- change `bucket` value in `main.tf` file to name of the bucket you just created
- adjust `variables.tf` and `local.tf` so the data matches your project, if you are not using vpn use `0.0.0.0/0` instead (it will make your application available from any IP)
- run `terraform init`

### Set up infrastructure 
- use `terraform plan` to review what elements will be created 
- use `terraform apply` to set up the rest of the infrastructure (it will take a while)

### Running code locally 
- in folder `Churning/src/` create `.env` file base on template
- `classifiers.py` - This hyperparameter tunes a model, tracks and logs the runs using the MLFlow from the cloud and saves the best run as a model inside the s3 bucket.

## Timeframe
This project took around 3 days, and was moslty to help me learn about Terraform and about the Cloud (AWS). 

## Roadmap
* Add Images to README of test run
* Look into building the environment using EC2 instance instead of docker.

## Contributors
This project uses the template found [here](https://github.com/dlabsai/mlflow-for-gcp)