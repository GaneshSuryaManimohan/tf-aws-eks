resource "aws_instance" "workstation" {
  instance_type          = "t3.small"
  ami                    = data.aws_ami.ami_info.id
  vpc_security_group_ids = [var.sg_id]
  subnet_id              = var.public_subnet_ids
  user_data              = file("workstation.sh")
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
  tags = {
    Name = "workstation"
  }
}