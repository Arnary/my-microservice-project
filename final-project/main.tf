module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "final-project-hw-140083317091"
  table_name  = "terraform-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "final-project-hw-vpc"
}

module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "final-project-hw-ecr"
  scan_on_push = true
}

provider "aws" {
  region = "eu-central-1"
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "final-project-hw-cluster"
  subnet_ids      = module.vpc.public_subnets
  instance_type   = "t2.medium"
  desired_size    = 2
  min_size        = 2
  max_size        = 2
}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

module "jenkins" {
  source       = "./modules/jenkins"
  cluster_name = module.eks.eks_cluster_name

  providers = {
    helm = helm
  }
}

module "argo_cd" {
  source       = "./modules/argo_cd"
  namespace    = "argocd"
  chart_version = "5.46.4"
}

module "rds" {
  source = "./modules/rds"

  name                       = "django-db"

  # Тип бази даних
  use_aurora                 = true

  aurora_instance_count      = 2

  # --- Aurora-only ---
  engine_cluster             = "aurora-postgresql"
  engine_version_cluster     = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"
  

  # --- RDS-only ---
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Common
  instance_class             = "db.t3.medium"
  allocated_storage          = 20
  db_name                    = "djangoapp"
  username                   = "postgres"
  password                   = "admin123AWS23"
  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  publicly_accessible        = true
  vpc_id                     = module.vpc.vpc_id
  multi_az                   = true
  backup_retention_period    = 7
  parameters = {
    max_connections              = "200"
    log_min_duration_statement   = "500"
  }

  tags = {
    Environment = "dev"
    Project     = "djangoapp"
  }
}

module "monitoring" {
  source = "./modules/monitoring"
  
  namespace               = "monitoring"
  prometheus_chart_version = var.prometheus_chart_version
  
  # Grafana налаштування
  grafana_admin_password = var.grafana_admin_password
  
  # Зберігання
  prometheus_retention      = var.prometheus_retention
  prometheus_storage_size   = var.prometheus_storage_size
  grafana_storage_size      = var.grafana_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size
  
  # Компоненти
  enable_alertmanager       = var.enable_alertmanager
  enable_node_exporter      = var.enable_node_exporter
  enable_kube_state_metrics = var.enable_kube_state_metrics
  
  # Сповіщення
  slack_webhook_url = var.slack_webhook_url
  slack_channel     = var.slack_channel
  
  # Ingress (опціонально)
  create_ingress          = var.create_monitoring_ingress
  grafana_hostname        = var.grafana_hostname
  prometheus_hostname     = var.prometheus_hostname
  alertmanager_hostname   = var.alertmanager_hostname
  
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
  
  depends_on = [module.eks]
}
