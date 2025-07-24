# final-project: Розгортання інфраструктури DevOps на AWS

Комплексна інфраструктура для Django додатка з використанням AWS EKS, Jenkins CI/CD, ArgoCD, RDS/Aurora та моніторингом Prometheus + Grafana.

- **Terraform** - для управління інфраструктурою як кодом.
- **Amazon Web Services (AWS)**:
  - S3 + DynamoDB - для зберігання стейтів Terraform.
  - ECR - для зберігання Docker-образів.
  - EKS - для запуску Kubernetes-кластера.
  - VPC - для приватної мережі.
  - RDS - для бази даних.
- **Docker** - контейнеризація Django-додатку.
- **Kubernetes + Helm** - для автоматичного деплою в кластер.
- **Jenkins** - CI/CD сервер для автоматизації збірки.
- **Argo CD** - GitOps Continuous Deployment для Kubernetes.
- **AWS RDS** - для створення та управління реляційною базою даних.
- **Prometheus** - збір та зберігання метрик.
- **Grafana** - візуалізація метрик та дашборди.
- **AlertManager** - керування сповіщеннями.

## Структура проекту

```
django-app/
│
├── app/
├── Dockerfile
├── Jenkinsfile
├── docker-compose.yml
├── manage.py
├── requirements.txt
│
final-project/
│
├── main.tf                  <- Головний файл для підключення модулів
├── backend.tf               <- Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               <- Загальні виводи ресурсів
│
├── modules/                 <- Каталог з усіма модулями
│   ├── s3-backend/          <- Модуль для S3 та DynamoDB
│   │   ├── s3.tf            <- Створення S3-бакета
│   │   ├── dynamodb.tf      <- Створення DynamoDB
│   │   ├── variables.tf     <- Змінні для S3
│   │   └── outputs.tf       <- Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 <- Модуль для VPC
│   │   ├── vpc.tf           <- Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        <- Налаштування маршрутизації
│   │   ├── variables.tf     <- Змінні для VPC
│   │   └── outputs.tf
│   ├── ecr/                 <- Модуль для ECR
│   │   ├── ecr.tf           <- Створення ECR репозиторію
│   │   ├── variables.tf     <- Змінні для ECR
│   │   └── outputs.tf       <- Виведення URL репозиторію
│   │
│   ├── eks/                      <- Модуль для Kubernetes кластера
│   │   ├── eks.tf                <- Створення кластера
│   │   ├── aws_ebs_csi_driver.tf <- Встановлення плагіну csi drive
│   │   ├── variables.tf          <- Змінні для EKS
│   │   └── outputs.tf            <- Виведення інформації про кластер
│   │
│   ├── rds/                 <- Модуль для RDS
│   │   ├── rds.tf           <- Створення RDS бази даних
│   │   ├── aurora.tf        <- Створення aurora кластера бази даних
│   │   ├── shared.tf        <- Спільні ресурси
│   │   ├── variables.tf     <- Змінні (ресурси, креденшели, values)
│   │   └── outputs.tf
│   │
│   ├── jenkins/             <- Модуль для Helm-установки Jenkins
│   │   ├── jenkins.tf       <- Helm release для Jenkins
│   │   ├── variables.tf     <- Змінні (ресурси, креденшели, values)
│   │   ├── providers.tf     <- Оголошення провайдерів
│   │   ├── values.yaml      <- Конфігурація jenkins
│   │   └── outputs.tf       <- Виводи (URL, пароль адміністратора)
│   │
│   └── argo_cd/             <- Модуль для Helm-установки Argo CD
│       ├── jenkins.tf       <- Helm release для Jenkins
│       ├── variables.tf     <- Змінні (версія чарта, namespace, repo URL тощо)
│       ├── providers.tf     <- Kubernetes+Helm.  переносимо з модуля jenkins
│       ├── values.yaml      <- Кастомна конфігурація Argo CD
│       ├── outputs.tf       <- Виводи (hostname, initial admin password)
│		    └──charts/                 <- Helm-чарт для створення app'ів
│ 	 	    ├── Chart.yaml
│	  	    ├── values.yaml          <- Список applications, repositories
│			    └── templates/
│		        ├── application.yaml
│		        └── repository.yaml
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     <- ConfigMap зі змінними середовища
```

## Команди для розгортання

1. Ініціалізація Terraform (завантаження модулів, підключення до бекенду)

```
cd final-project/
terraform init
```

2. Перевірка та попередній перегляд змін в інфраструктурі

```
terraform plan
```

3. Застосування змін, створення ресурсів

```
terraform apply
```

У результаті будуть створені:

- VPC з публічними та приватними підмережами
- S3 та DynamoDB для зберігання стану
- ECR-репозиторій для образів
- Kubernetes кластер (EKS)

Перевірити стан ресурсів:

```
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

4. Аутентифікація в AWS:

```
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.eu-central-1.amazonaws.com
```

5. Збірка та пуш образу:

```
docker build -t django-app ./django-app
docker tag django-app:latest <repo-url>:latest
docker push <repo-url>:latest
```

6. Налаштування kubeconfig:

```
aws eks --region eu-central-1 update-kubeconfig --name lesson7-eks-cluster
```

7. Встановлення Helm-чарту

```
cd charts/
helm install django-app ./django-app
```

Після виконання усіх кроків ви повинні отримати повністю розгорнутий Django-застосунок у Kubernetes-кластері AWS, з горизонтальним автоскейлінгом, зовнішнім доступом через LoadBalancer та конфігурацією змінних середовища через ConfigMap.

Перевірка доступності Jenkins та Argo CD:

```
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

Моніторинг та перевірка метрик:

```
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

8. Видалення всіх створених ресурсів

```
helm uninstall django-app
terraform destroy
```

## RDS Module

Універсальний Terraform модуль для створення RDS інстансу або Aurora кластера з автоматичним налаштуванням всіх необхідних ресурсів.

### Функціонал

- **Підтримка Aurora Cluster та звичайної RDS instance**
- **Автоматичне створення DB Subnet Group**
- **Автоматичне створення Security Group з налаштованими правилами**
- **Автоматичне створення Parameter Group з базовими параметрами**
- **Підтримка різних движків**: PostgreSQL, MySQL
- **Enhanced Monitoring та Performance Insights**
- **Multi-AZ deployment**
- **Автоматичні backup'и**

### Використання

Основний приклад (RDS Instance)

```
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
```

### Змінні модуля

#### Обов'язкові змінні

| Змінна               | Тип      | Опис                              |
| -------------------- | -------- | --------------------------------- |
| `password`           | `string` | Пароль для бази даних (sensitive) |
| `vpc_id`             | `string` | ID VPC для розміщення RDS         |
| `subnet_private_ids` | `string` | Список приватних ID підмереж      |
| `subnet_public_ids`  | `string` | Список публічних ID підмереж      |

#### Основні налаштування

| Змінна        | Тип      | За замовчуванням | Опис                                       |
| ------------- | -------- | ---------------- | ------------------------------------------ |
| `use_aurora`  | `bool`   | `false`          | Використовувати Aurora Cluster замість RDS |
| `name`        | `string` | `"django-db"`    | Назва проекту                              |
| `environment` | `string` | `"dev"`          | Назва середовища                           |
| `db_name`     | `string` | `"djangoapp"`    | Назва бази даних                           |
| `username`    | `string` | `"postgres"`     | Ім'я користувача                           |

#### Конфігурація движка

| Змінна           | Тип      | За замовчуванням | Опис                        |
| ---------------- | -------- | ---------------- | --------------------------- |
| `engine`         | `string` | `"postgres"`     | Движок БД (postgres, mysql) |
| `engine_version` | `string` | `"17.2"`         | Версія движка               |
| `instance_class` | `string` | `"db.t3.medium"` | Клас інстансу               |

#### Сховище (тільки для RDS)

| Змінна              | Тип      | За замовчуванням | Опис                   |
| ------------------- | -------- | ---------------- | ---------------------- |
| `allocated_storage` | `number` | `20`             | Початковий розмір в GB |

#### Безпека та мережа

| Змінна     | Тип    | За замовчуванням | Опис                |
| ---------- | ------ | ---------------- | ------------------- |
| `multi_az` | `bool` | `true`           | Multi-AZ deployment |

#### Backup та обслуговування

| Змінна                    | Тип      | За замовчуванням | Опис                              |
| ------------------------- | -------- | ---------------- | --------------------------------- |
| `backup_retention_period` | `number` | `7`              | Період збереження backup'ів (дні) |

#### Параметри БД

| Змінна            | Тип      | За замовчуванням | Опис                           |
| ----------------- | -------- | ---------------- | ------------------------------ |
| `max_connections` | `number` | `200`            | Максимальна кількість з'єднань |

### Як змінити конфігурацію БД

#### 1. Зміна типу бази даних (RDS ↔ Aurora)

```
# Для звичайної RDS
use_aurora = false

# Для Aurora Cluster
use_aurora = true
```

**Увага**: Зміна `use_aurora` призведе до перестворення всієї інфраструктури БД!

#### 2. Зміна движка бази даних

```
# PostgreSQL
engine         = "postgres"
engine_version = "15.4"        # Доступні: 13.x, 14.x, 15.x, 16.x

# MySQL
engine         = "mysql"
engine_version = "8.0.35"      # Доступні: 5.7.x, 8.0.x
```

#### 3. Зміна класу інстансу

```
# Development
instance_class = "db.t3.micro"   # 1 vCPU, 1 GB RAM

# Testing
instance_class = "db.t3.small"   # 2 vCPU, 2 GB RAM
instance_class = "db.t3.medium"  # 2 vCPU, 4 GB RAM

# Production
instance_class = "db.r6g.large"   # 2 vCPU, 16 GB RAM
instance_class = "db.r6g.xlarge"  # 4 vCPU, 32 GB RAM
instance_class = "db.r6g.2xlarge" # 8 vCPU, 64 GB RAM
```

#### 4. Налаштування сховища (тільки RDS)

```
# Малі БД
allocated_storage     = 20    # Початкових 20 GB

# Великі БД
allocated_storage     = 100   # Початкових 100 GB
```

#### 5. Продакшн налаштування

```
# Високодоступність
multi_az = true                 # Multi-AZ deployment

# Довгі backup'и
backup_retention_period = 30   # 30 днів backup'ів
```

#### 6. Оптимізація параметрів БД

```
# PostgreSQL оптимізація
max_connections = 200

# MySQL оптимізація
max_connections = 300
```

## Моніторинг та метрики

Після розгортання автоматично встановлюються дашборди:

- Kubernetes Cluster Monitoring
  - Загальний стан кластера
  - Ресурси вузлів
  - Мережевий трафік

---

- Kubernetes Pod Monitoring
  - Стан подів
  - Ресурси контейнерів
  - Restart'и та помилки

---

- Node Exporter
  - CPU, Memory, Disk
  - Мережеві інтерфейси
  - Завантаження системи

---

- Kubernetes Deployment
  - Стан deployment'ів
  - Replica sets
  - Rolling updates

## Алерти

Автоматично налаштовані алерти:

- HighMemoryUsage: >80% використання пам'яті контейнером
- HighCPUUsage: >80% використання CPU
- PodRestarting: Часті restart'и подів
- KubernetesPodCrashLooping: Pod в crash loop
- KubernetesNodeNotReady: Вузол недоступний
