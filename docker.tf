resource "docker_image" "mlflow_image" {
  name = aws_ecr_repository.mlflow_ecr.repository_url

  build {
    context    = abspath("${path.module}/mlflow_docker")  # Path to the directory containing the Dockerfile
    dockerfile = "Dockerfile"  # Name of the Dockerfile
  }
  depends_on = [aws_ecr_repository.mlflow_ecr]
}


resource "null_resource" "docker_login_and_push" {
  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command = <<-EOT
      $password = aws ecr get-login-password --region ${var.region}
      docker login --password $password --username AWS "${aws_ecr_repository.mlflow_ecr.repository_url}"
      docker push ${aws_ecr_repository.mlflow_ecr.repository_url}:latest

    EOT
  }
  depends_on = [aws_ecr_repository.mlflow_ecr]
}

      # aws ecr get-login-password --region ${var.region}   | docker login --password-stdin --username AWS "${aws_ecr_repository.mlflow_ecr.repository_url}"
      # docker push ${aws_ecr_repository.mlflow_ecr.repository_url}:latest

      # $password = aws ecr get-login-password --region eu-west-1
      # $password
      # docker login --username AWS --password-stdin $password ${aws_ecr_repository.mlflow_ecr.repository_url}
      # docker push ${aws_ecr_repository.mlflow_ecr.repository_url}:latest

# resource "null_resource" "docker_login_and_push" {
#   provisioner "local-exec" {
#     interpreter = ["PowerShell", "-Command"]
#     command = <<-EOT
# try {
#     # Fetch the ECR login password
#     $password = aws ecr get-login-password --region ${var.region}
#     if ([string]::IsNullOrWhiteSpace($password)) {
#         throw "Failed to retrieve ECR login password."
#     }
# # Login to Docker
#     $dockerLoginResult = echo $password | docker login --username AWS --password-stdin ${aws_ecr_repository.mlflow_ecr.repository_url}
#     if ($dockerLoginResult -match "Login Succeeded") {
#         Write-Output "Docker login succeeded."

#         # Push the Docker image
#         $dockerPushResult = docker push ${aws_ecr_repository.mlflow_ecr.repository_url}:latest
#         Write-Output $dockerPushResult
#     } 
# else {
#         throw "Docker login failed: $dockerLoginResult"
#     }
# } 

# catch {
#     Write-Error "Error occurred: $_"
#     exit 1
# }
    
#     EOT
#   }
#   depends_on = [aws_ecr_repository.mlflow_ecr]
# }
