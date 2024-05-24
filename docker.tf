resource "docker_image" "mlflow_image" {
  name = aws_ecr_repository.mlflow_ecr.repository_url

  build {
    context    = abspath("${path.module}/mlflow_docker")  # Path to the directory containing the Dockerfile for MLFlow
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
