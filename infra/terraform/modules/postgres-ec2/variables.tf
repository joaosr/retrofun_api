variable "name" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "key_name" {}
variable "allowed_cidrs" { type = list(string) }
variable "tags" { type = map(string) }

variable "ami_id" { default = "ami-123456" }
variable "instance_type" { default = "r7g.large" }

# EBS pgdata
variable "pgdata_size" { default = 200 }
variable "pgdata_type" { default = "gp3" }
variable "pgdata_iops" { default = 6000 }
variable "pgdata_throughput" { default = 250 }

# CloudWatch SNS topic
variable "alarm_topic_arn" {}
