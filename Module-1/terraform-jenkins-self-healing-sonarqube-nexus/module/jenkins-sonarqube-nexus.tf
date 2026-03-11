# Security Group for ALB
resource "aws_security_group" "security_group_alb" {
  name        = "Security-Group-ALB"
  description = "Security Group for ALB"
  vpc_id      = var.vpc_id

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
    Name = "Security-Group-ALB"
  }
}

#S3 Bucket to capture ALB access logs
resource "aws_s3_bucket" "s3_bucket" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = var.access_log_bucket

  force_destroy = true

  tags = {
    Environment = var.env
  }
}

#S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3bucket_encryption" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

data "aws_caller_identity" "G_Duty" {
}

#Apply Bucket Policy to S3 Bucket
resource "aws_s3_bucket_policy" "s3bucket_policy_jenkins_nexus_sonarqube" {
  count = var.s3_bucket_exists == false ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
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
         "Resource": "arn:aws:s3:::s3bucketcapturealblog/application_loadbalancer_log_folder_jenkins/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*"
         },
         {
           "Effect": "Allow",
           "Principal": {
             "AWS": "arn:aws:iam::033677994240:root"
         },
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::s3bucketcapturealblog/application_loadbalancer_log_folder_nexus/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*"
         },
         {
           "Effect": "Allow",
           "Principal": {
             "AWS": "arn:aws:iam::033677994240:root"
         },
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::s3bucketcapturealblog/application_loadbalancer_log_folder_sonarqube/AWSLogs/${data.aws_caller_identity.G_Duty.account_id}/*"
         }
       ]
    }
  EOF

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.s3bucket_encryption]
}

resource "aws_lb" "test-application-loadbalancer" {
  count              = 3
  name               = count.index == 0 ? "jenkins-alb" : (count.index == 1 ? "nexus-alb" : "sonarqube-alb")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group_alb.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false
  idle_timeout = 60
  access_logs {
    bucket  = var.access_log_bucket
    prefix  = count.index == 0 ? "application_loadbalancer_log_folder_jenkins" : (count.index == 1 ? "application_loadbalancer_log_folder_nexus" : "application_loadbalancer_log_folder_sonarqube")
    enabled = true
  }

  tags = {
    Environment = "Dev"
  }
}

#Target Group of Application Loadbalancer
resource "aws_lb_target_group" "target_group" {
  count    = 3
  name     = count.index == 0 ? "jenkins-TG" : (count.index == 1 ? "nexus-TG" : "sonarqube-TG")
  port     = count.index == 0 ? "8080" : (count.index == 1 ? "8081" : "9000")      ##### Don't use protocol when target type is lambda
  protocol = "HTTP"  ##### Don't use protocol when target type is lambda
  vpc_id   = var.vpc_id
  target_type = "instance"
  load_balancing_algorithm_type = "round_robin"
  health_check {
    enabled = true ## Indicates whether health checks are enabled. Defaults to true.
    path = count.index == 0 ? "/login" : (count.index == 1 ? "/" : "/")
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 40
  }
}

##Application Loadbalancer listener for HTTP
resource "aws_lb_listener" "alb_listener_front_end_HTTP" {
  count             = 3
  load_balancer_arn = aws_lb.test-application-loadbalancer[count.index].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.target_group[count.index].arn
     redirect {    ### Redirect HTTP to HTTPS
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

##Application Loadbalancer listener for HTTPS
resource "aws_lb_listener" "alb_listener_front_end_HTTPS" {
  count             = 3
  load_balancer_arn = aws_lb.test-application-loadbalancer[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate.acm_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[count.index].arn
  }
}

## EC2 Instance attachment to the Target Group
resource "aws_lb_target_group_attachment" "ec2_instance_attachment" {
  count            = 2
  target_group_arn = count.index == 0 ? aws_lb_target_group.target_group[1].arn : aws_lb_target_group.target_group[2].arn
  target_id        = count.index == 0 ? aws_instance.nexus_sonarqube[0].id : aws_instance.nexus_sonarqube[1].id
  port             = count.index == 0 ? "8081" : "9000"
}

# Security Group for Jenkins-Master
resource "aws_security_group" "jenkins_master" {
  name        = "Jenkins-master"
  description = "Security Group for Jenkins Master ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups  = [aws_security_group.security_group_alb.id]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-master-sg"
  }
}

# Security Group for Nexus-Server
resource "aws_security_group" "nexus" {
  name        = "Nexus"
  description = "Security Group for Nexus Server"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    security_groups  = [aws_security_group.security_group_alb.id]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nexus-server-sg"
  }
}

# Security Group for SonarQube Server
resource "aws_security_group" "sonarqube" {
  name        = "SonarQube"
  description = "Security Group for SonarQube Server"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    security_groups  = [aws_security_group.security_group_alb.id]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SonarQube-Server-sg"
  }
}

resource "aws_launch_template" "demo_launch_template" {
  name          = "jenkins-launch-template"
  image_id      = var.provide_ami
  instance_type = var.instance_type[2]
#  iam_instance_profile = "Administrator_Access"   ### IAM Role to be attached to EC2
  ebs_optimized = true
#  key_name = var.key_name
#  vpc_security_group_ids = count.index == 0 ? [aws_security_group.jenkins_master.id] : (count.index == 1 ? [aws_security_group.nexus.id] : [aws_security_group.sonarqube.id])
  user_data = base64encode(templatefile("jenkins_master.sh", {jenkins_efs_ip_address = aws_efs_mount_target.efs_mount_target.ip_address}))
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      encrypted = true
      kms_key_id = var.kms_key_id     ### Provide the kms_key_id for your AWS Account.
    }
  }
  placement {
    tenancy = "default"
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.jenkins_master.id]
  }
  monitoring {
    enabled = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "demo_autoscaling_group" {
  name                 = "jenkins-autostacling-group"
  min_size = 1
  max_size = 1
  desired_capacity = 1
  vpc_zone_identifier = [var.public_subnets[0]]
  default_cooldown = 10                   ##Time between a scaling activity and the succeeding scaling activity.
  service_linked_role_arn = var.service_linked_role_arn
  health_check_grace_period = 600
  health_check_type = "ELB"
  force_delete = true 
  target_group_arns = [aws_lb_target_group.target_group[0].arn]
  termination_policies = ["OldestInstance"]
  launch_template {
    id      = aws_launch_template.demo_launch_template.id
    version = aws_launch_template.demo_launch_template.latest_version
  }
  tag {
    key = "Environment" 
    value = "Dev"
    propagate_at_launch = true  ### Tags automatically inherited by EC2 Instances.
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_efs_mount_target.efs_mount_target]
}

resource "aws_security_group" "efs_ingress" {
  name   = "efs-ingress-jenkins"
  vpc_id = var.vpc_id

  ingress {

    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.jenkins_master.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "jenkins_EFS" {
  creation_token   = "Jenkins-EFS"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"
  tags = {
    Name = "Elastic-File-System-Jenkins"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id  = aws_efs_file_system.jenkins_EFS.id
  subnet_id       = var.public_subnets[0]
  security_groups = [aws_security_group.efs_ingress.id]
}

resource "aws_instance" "nexus_sonarqube" {
  count         = 2
  ami           = var.provide_ami
  instance_type = var.instance_type[2]
  monitoring    = true
  vpc_security_group_ids = count.index == 0 ? [aws_security_group.nexus.id] : [aws_security_group.sonarqube.id]
  subnet_id = var.public_subnets[count.index]
  root_block_device{
    volume_type="gp3"
    volume_size="20"
    encrypted=true
    kms_key_id = var.kms_key_id
    delete_on_termination=true
  }
  user_data = count.index == 0 ? file("nexus.sh") : templatefile("sonarqube.sh", {RDS_ENDPOINT = aws_db_instance.dbinstance1.endpoint 
                                                                                               USERNAME=jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"] 
                                                                                               PASSWORD=jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]
                                                                                               SQ_USERNAME=var.sq_username
                                                                                               SQ_PASSWORD=var.sq_password})  

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
    Name = count.index == 0 ? "Nexus-Server" : "SonarQube-Server"
    Environment = var.env
  }

  depends_on = [aws_db_instance.dbinstance1]

}
resource "aws_eip" "eip_associate_nexus_sonarqube" {
  count  = 2
  domain = "vpc"     ###vpc = true
}
resource "aws_eip_association" "eip_association_nexus_sonarqube" {  ### I will use this EC2 behind the ALB.
  count         = 2
  instance_id   = aws_instance.nexus_sonarqube[count.index].id
  allocation_id = aws_eip.eip_associate_nexus_sonarqube[count.index].id
}
