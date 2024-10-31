variable "nginx_image" {
  description = "ECR URI của container ứng dụng (nginx)"
  type        = string
  default     = "257394455086.dkr.ecr.us-west-2.amazonaws.com/server:latest"
}

variable "mysql_image" {
  description = "ECR URI của container MySQL"
  type        = string
  default     = "257394455086.dkr.ecr.us-west-2.amazonaws.com/mysql:latest"
}
variable "cpu" {
  description = "CPU cho task"
  type        = string
  default     = "1024"
}

variable "memory" {
  description = "Dung lượng bộ nhớ cho task"
  type        = string
  default     = "2048"
}
variable "execution_role_arn"{
    description = "ARN của IAM Role cho ECS Task"
    type        = string
    default     = "arn:aws:iam::257394455086:role/ecsTaskExecutionRole"
}
variable "task_role_arn"{
    description = "ARN của IAM Role cho ECS Task"
    type        = string
    default     = "arn:aws:iam::257394455086:role/ecsTaskExecutionRole"
}
variable "region" {
  type        = string
  default     = "us-west-2"
  description = "regions"
}
variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "instance type"
}
variable "certificate_arn" {
    description = "ARN của SSL Certificate"
    type        = string
    default     = "arn:aws:acm:us-west-2:257394455086:certificate/69f7dd38-5717-4130-a930-0f10ff74cf83"
}
# variable "route53_zone" {
#     description = "Tên miền của bản ghi Route 53 trỏ đến ALB"
#     type        = string
#     default     = "aic-uog.tech"
# }
# variable "route53_type_record" {
#     description = "Loại bản ghi Route 53"
#     type        = string
#     default     = "A"
# }
# variable "route53_record" {
#     description = "Tên miền của bản ghi Route 53 trỏ đến ALB"
#     type        = string
#     default     = "aic-uog.tech"
# }
