# lesson-8-9: Реалізація повного CI/CD-процесу із використанням Jenkins + Helm + Terraform + Argo CD

- **Terraform** - для управління інфраструктурою як кодом.
- **Amazon Web Services (AWS)**:
  - S3 + DynamoDB - для зберігання стейтів Terraform.
  - ECR - для зберігання Docker-образів.
  - EKS - для запуску Kubernetes-кластера.
  - VPC - для приватної мережі.
- **Docker** - контейнеризація Django-додатку.
- **Kubernetes + Helm** - для автоматичного деплою в кластер.
- **Jenkins** - CI/CD сервер для автоматизації збірки.
- **Argo CD** - GitOps Continuous Deployment для Kubernetes.

## Структура проекту

```
lesson-8-9/
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
cd lesson-8-9/
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

8. Видалення всіх створених ресурсів

```
helm uninstall django-app
terraform destroy
```
