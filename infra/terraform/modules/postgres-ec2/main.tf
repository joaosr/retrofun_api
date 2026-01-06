# ------------------------------
# SECURITY GROUP
# ------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Postgres SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ------------------------------
# EC2 INSTANCE
# ------------------------------
resource "aws_instance" "postgres" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  # Root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

# ------------------------------
# DATA (PGDATA) VOLUME
# ------------------------------
resource "aws_ebs_volume" "pgdata" {
  availability_zone = aws_instance.postgres.availability_zone
  size              = var.pgdata_size
  type              = var.pgdata_type   # gp3 or io2
  iops              = var.pgdata_iops
  throughput        = var.pgdata_throughput

  tags = merge(var.tags, {
    Name = "${var.name}-pgdata"
  })
}

resource "aws_volume_attachment" "pgdata_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.pgdata.id
  instance_id = aws_instance.postgres.id
}

# ------------------------------
# CLOUDWATCH ALARMS
# ------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "High CPU on Postgres"
  dimensions = {
    InstanceId = aws_instance.postgres.id
  }
  alarm_actions = [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "disk_low" {
  alarm_name          = "${var.name}-disk-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Minimum"
  threshold           = 5_000_000_000   # 5 GB
  alarm_description   = "Low free disk on Postgres"
  alarm_actions       = [var.alarm_topic_arn]
}
