resource "aws_s3_bucket" "bucket_scripts" {
  bucket = "dedeyjbucketscripts" 
  force_destroy = true
}

resource "aws_s3_object" "data-upload" {
  bucket = aws_s3_bucket.bucket_scripts.id
  key    = "data/BankChurners.csv"                         # this should be the path expected on your bucket!
  source = "./Churning/data/BankChurners.csv"            # relative path to your local file
  etag = filemd5("./Churning/data/BankChurners.csv")     # relative path to your local file
}

resource "aws_s3_object" "script1-upload" {
  bucket = aws_s3_bucket.bucket_scripts.id
  key    = "src/classifiers.py"                      # this should be the path expected on your bucket!
  source = "./Churning/src/classifiers.py"         # relative path to your local file
  etag = filemd5("./Churning/src/classifiers.py")  # relative path to your local file
}

resource "aws_glue_job" "local-job-name" {
  name         = "your-job-name"
  role_arn     = aws_iam_role.glue_role.arn             # your glue role local name
  glue_version = "4.0"
  description  = "foo"
  command {
    name            = "pythonshell"
    python_version   = "3.9"
    script_location = "s3://${aws_s3_bucket.bucket_scripts.bucket}/src/classifiers.py"
  }
  max_capacity = "0.0625"
  default_arguments = {
    # "--extra-py-files" = "s3://${aws_s3_bucket.bucket_scripts.bucket}/src/modules.zip"
    # "--pip-install" = "pandas,numpy,scikit-learn,boto3,imbalanced-learn,optuna,mlflow==2.4.1"
    "--additional-python-modules" = "pandas,numpy,scikit-learn,boto3,imbalanced-learn,optuna,mlflow==2.4.1"
    # this is how you install extra libraries in ray
    # in case you need an extra one, you should pass the name and version here
  }
}

resource "aws_iam_role" "glue_role" {                   # the permission role starts here
  name = "your-glue-role-jens"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_policy" "glue_s3_full_access_policy" {          
  name        = "GlueS3FullAccessPolicy"                            # don't change the name here
  description = "Policy to allow full access to S3 for Glue jobs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_full_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_service_role_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"    # and ends here
}

# Retrieve the AWS account ID
data "aws_caller_identity" "current" {}

# Define the IAM policy to allow GetParameter action on the specified SSM parameter
resource "aws_iam_policy" "glue_ssm_policy" {
  name        = "GlueSSMGetParameterPolicy"
  description = "Policy to allow Glue job to get SSM parameters"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
        ],
        Resource =[
             "arn:aws:ssm:eu-west-1:${data.aws_caller_identity.current.account_id}:parameter/mlflow/tracking_uri",
             "arn:aws:ssm:eu-west-1:${data.aws_caller_identity.current.account_id}:parameter/mlflow-terraform/MLFLOW_TRACKING_PASSWORD"
                  ]
      },
    ],
  })
}

# Attach the policy to the existing Glue role
resource "aws_iam_role_policy_attachment" "glue_ssm_policy_attachment" {
  role       = "your-glue-role-jens" # Replace with your actual Glue role name if different
  policy_arn = aws_iam_policy.glue_ssm_policy.arn
}

