#S3 Bucket to capture RabbitMQ ALB access logs
resource "aws_s3_bucket" "s3_bucket_rabbitmq" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = "s3bucketcapturealblograbbitmq"
  
  force_destroy = true

  tags = {
    Environment = var.env
  }
}

#S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3bucket_encryption_rabbitmq" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket_rabbitmq[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

#Apply Bucket Policy to S3 Bucket
resource "aws_s3_bucket_policy" "s3bucket_policy_rabbitmq" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket_rabbitmq[0].id
  policy = <<EOF
    {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Principal": {
             "AWS": "arn:aws:iam::033677994240:root"
         },
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::s3bucketcapturealblograbbitmq/application_loadbalancer_log_folder/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*"
         }
       ]
    }     
  EOF
  
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.s3bucket_encryption_rabbitmq]
}

#################################################### RabbitMQ ALB #####################################################################

# Security Group for RabbitMQ ALB
resource "aws_security_group" "rabbitmq_alb" {
  name        = "RabbitMQ-ALB-SecurityGroup"
  description = "Security Group for RabbitMQ ALB"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = var.cidr_blocks
    from_port  = 80
    to_port    = 80
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RabbitMQ-ALB-sg"
  }
}

#RabbitMQ Application Loadbalancer
resource "aws_lb" "rabbitmq-application-loadbalancer" {
  name               = "RabbitMQ-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rabbitmq_alb.id]           ###var.security_groups
  subnets            = aws_subnet.public_subnet.*.id                  ###var.subnets

  enable_deletion_protection = false
  idle_timeout = 60
  access_logs {
    bucket  = "s3bucketcapturealblograbbitmq"
    prefix  = "application_loadbalancer_log_folder"
    enabled = true
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_s3_bucket_policy.s3bucket_policy_rabbitmq]
}

#Target Group of RabbitMQ Application Loadbalancer
resource "aws_lb_target_group" "rabbitmq_target_group" {
  name     = "RabbitMQ"
  port     = 15672      ##### Don't use protocol when target type is lambda
  protocol = "HTTP"     ##### Don't use protocol when target type is lambda
  vpc_id   = aws_vpc.test_vpc.id    #####var.vpc_id
  target_type = "instance"
  load_balancing_algorithm_type = "round_robin"
  health_check {
    enabled = true ## Indicates whether health checks are enabled. Defaults to true.
    path = "/"     ###"/index.html"
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

##RabbitMQ Application Loadbalancer listener for HTTP
resource "aws_lb_listener" "rabbitmq_alb_listener_front_end_HTTP" {
  load_balancer_arn = aws_lb.rabbitmq-application-loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.rabbitmq_target_group.arn
     redirect {    ### Redirect HTTP to HTTPS
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

##RabbitMQ Application Loadbalancer listener for HTTPS
resource "aws_lb_listener" "rabbitmq_alb_listener_front_end_HTTPS" {
  load_balancer_arn = aws_lb.rabbitmq-application-loadbalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate.acm_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_target_group.arn
  }

  depends_on = [aws_acm_certificate_validation.acm_certificate_validation]
}

## EC2 Instance1 attachment to RabbitMQ Target Group
resource "aws_lb_target_group_attachment" "rabbitmq_instance_attachment_to_tg" {
  count            = 3
  target_group_arn = aws_lb_target_group.rabbitmq_target_group.arn
  target_id        = aws_instance.rabbitmq[count.index].id        #var.ec2_instance_id[0]
  port             = 15672
}

################################################################ RabbitMQ ##########################################################################

# Security Group for RabbitMQ Server
resource "aws_security_group" "rabbitmq" {
  name        = "RabbitMQ"
  description = "Security Group for RabbitMQ Server"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 15672
    to_port          = 15672
    protocol         = "tcp"
    security_groups  = [aws_security_group.rabbitmq_alb.id]
  }

  ingress {
    from_port        = 5672
    to_port          = 5672
    protocol         = "tcp"
    cidr_blocks      = ["10.224.0.0/12", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20", "192.168.0.0/16"]
  }

  ingress {
    from_port        = 25672
    to_port          = 25672
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
  }

  ingress {
    from_port        = 4369
    to_port          = 4369
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RabbitMQ-Server-sg"
  }
}

############################################################# RabbitMQ Server ###########################################################################

resource "aws_instance" "rabbitmq" {
  count         = 3
  ami           = var.provide_ami
  instance_type = var.instance_type[0]
  monitoring = true
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]  ### var.vpc_security_group_ids       ###[aws_security_group.all_traffic.id]
  subnet_id = aws_subnet.public_subnet[0].id                   ### var.subnet_id
  root_block_device{
    volume_type="gp3"
    volume_size="20"
    encrypted=true
    kms_key_id = var.kms_key_id
    delete_on_termination=true
  }
  user_data = file("user_data_rabbitmq.sh")

  lifecycle{
    prevent_destroy=false
    ignore_changes=[ ami ]
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }

  metadata_options { #Enabling IMDSv2
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  tags={
    Name="${var.prefix}-ec2-rabbitmq-${count.index + 1}"
    Environment = var.env
  }

  depends_on = [aws_ebs_volume.extra_volume]
}
resource "aws_eip" "eip_associate_rabbitmq" {
  count  = 3
  domain = "vpc"     ###vpc = true
}
resource "aws_eip_association" "eip_association_rabbitmq" {  ### I will use this EC2 behind the ALB.
  count         = 3
  instance_id   = aws_instance.rabbitmq[count.index].id
  allocation_id = aws_eip.eip_associate_rabbitmq[count.index].id
}

# Create the extra EBS volume
resource "aws_ebs_volume" "extra_volume" {
  count             = 3
  availability_zone = aws_subnet.public_subnet[0].availability_zone
  size              = 10 # Size in GiB
  type              = "gp3"

  tags = {
    Name = "ec2-ExtraVolume-${count.index + 1}"
  }
}

# Attach the volume to the instance
resource "aws_volume_attachment" "ebs_attachment" {
  count       = 3
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.extra_volume[count.index].id
  instance_id = aws_instance.rabbitmq[count.index].id
}

