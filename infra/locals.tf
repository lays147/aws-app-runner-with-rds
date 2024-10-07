data "aws_availability_zones" "available" {}

locals {
  name   = "my-node-on-aws"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  postgres = {
    user     = "postgres"
    database = "postgres"
    port     = 5432
  }
  application = {
    port = 3000
  }

  github_oidc_domain = "token.actions.githubusercontent.com"
  # https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy
  # reponame = "repo:lays147/aws-app-runner-with-rds:ref:refs/tags/*"
  reponame = "repo:lays147/aws-app-runner-with-rds:ref:refs/heads/main"
}
