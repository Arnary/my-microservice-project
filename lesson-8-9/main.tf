module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-7-hw-140083317091"
  table_name  = "terraform-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "lesson-7-hw-vpc"
}

module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "lesson-7-hw-ecr"
  scan_on_push = true
}

provider "aws" {
  region = "eu-central-1"
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "lesson-7-hw-cluster"
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
  source       = "./modules/argo-cd"
  namespace    = "argocd"
  chart_version = "5.46.4"
}
