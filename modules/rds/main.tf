resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rds"
  description = "Postgres access from inside the VPC only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "Postgres from the cluster node groups"
  }

  # A database has no business reaching the internet. Egress is held to the
  # VPC so it can still talk to S3 through the gateway endpoint.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Outbound within the VPC only"
  }

  tags = var.tags
}

# Generated, stored in Secrets Manager, never in state as plaintext and never
# in a tfvars file. The password is read by the application through IRSA.
resource "aws_kms_key" "db" {
  description             = "RDS storage, snapshots, insights and secret for ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}

resource "aws_kms_alias" "db" {
  name          = "alias/${var.name}-rds"
  target_key_id = aws_kms_key.db.key_id
}

resource "random_password" "master" {
  length  = 32
  special = true
  # RDS rejects these in a master password and the error arrives 8 minutes
  # into an apply.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name}/postgres"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.db.arn
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = var.database_name
  })
}

# deletion_protection is var-driven: true in prod, false in staging so a
# teardown does not need a console visit. trivy cannot resolve the
# variable and assumes the worst.
#trivy:ignore:AVD-AWS-0177
resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.db.arn

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:03:30-sun:04:30"
  copy_tags_to_snapshot   = true

  # A final snapshot on destroy, always. The one time it is skipped is the
  # time it was needed.
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final-${formatdate("YYYYMMDDhhmm", timestamp())}"
  deletion_protection       = var.deletion_protection

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.db.arn
  performance_insights_retention_period = 7
  iam_database_authentication_enabled   = true
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  auto_minor_version_upgrade            = true

  lifecycle {
    # timestamp() in the snapshot name would otherwise force a diff on
    # every single plan.
    ignore_changes = [final_snapshot_identifier, password]
  }

  tags = var.tags
}
