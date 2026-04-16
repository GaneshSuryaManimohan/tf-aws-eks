# Create a bastion EC2 instance using the terraform-aws-modules/ec2-instance/aws module
module "bastion_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws" # using EC2 instance module
  name = "${var.project_name}-${var.environment}-bastion"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.bastion_sg_id.value]
  # this will select the first public subnet from the comma-separated list
  #subnet_id = element(split(",", data.aws_ssm_parameter.public_subnet_ids.value), 0)
  subnet_id = split(",", data.aws_ssm_parameter.public_subnet_ids.value)[0]
  ami = data.aws_ami.ami_info.id
  user_data = file("bastion.sh")
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion"
    }
  )
}