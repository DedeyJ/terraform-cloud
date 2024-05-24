locals {
  # Common tags to be assigned to all resources, can be changed
  tags = {
    Name        = "mlflow-terraform"
    Environment = var.env
  }
}