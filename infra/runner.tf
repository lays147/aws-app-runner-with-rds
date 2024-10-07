module "runner" {
  source         = "terraform-aws-modules/app-runner/aws"
  version        = "v1.2.0"
  create_service = true

  service_name = local.name
  instance_configuration = {
    cpu    = "256"
    memory = "512"
  }

  instance_policy_statements = {
    GetSecretValue = {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.db.db_instance_master_user_secret_arn]
    }
  }

  create_vpc_connector          = true
  vpc_connector_subnets         = module.vpc.private_subnets
  vpc_connector_security_groups = [module.security_group.security_group_id]

  network_configuration = {
    ingress_configuration = {
      is_publicly_accessible = true
    }
    egress_configuration = {
      egress_type = "VPC"
    }
  }

  source_configuration = {
    authentication_configuration = null
    auto_deployments_enabled     = true
    image_repository = {
      image_configuration = {
        port = local.application.port
        runtime_environment_secrets = {
          POSTGRES_SECRET = module.db.db_instance_master_user_secret_arn
        }
        runtime_environment_variables = {
          NODE_ENV          = "production"
          POSTGRES_USERNAME = local.postgres.user
          POSTGRES_DATABASE = local.postgres.database
          POSTGRES_PORT     = local.postgres.port
          POSTGRES_HOST     = module.db.db_instance_address
        }
      }
      image_identifier      = "${aws_ecr_repository.this.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }

  health_check_configuration = {
    path     = "/health"
    protocol = "HTTP"
  }

  private_ecr_arn        = aws_ecr_repository.this.arn
  create_access_iam_role = true
  depends_on             = [aws_ecr_repository.this, module.db]
}
