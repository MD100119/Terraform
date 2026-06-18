variable "ami_id" {
    description = "The AMI ID for the EC2 instance"
    type        = string
    default     = "ami-07a00cf47dbbc844c" # Example AMI ID, replace with your desired AMI
}

variable "instance_type" {
    description = "The instance type for the EC2 instance"
    type        = string
    default     = "t2.large"
}

# variable "security_group_id" {
#     description = "The security group ID for the EC2 instance"
#     type        = string
#     default     = "sg-0e3792b43ac0e1cf0" # Example security group ID, replace with your actual security group ID
# }

# variable "security_group_id" {
#   type        = list(string)
#   default     = ["sg-0e3792b43ac0e1cf0"]
# }

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1" # Example region, replace with your desired region
}