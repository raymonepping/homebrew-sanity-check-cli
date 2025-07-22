resource "aws_instance" "bad_example" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
  foo           = "bar"
}

variable "unused_var" {}
