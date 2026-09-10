# Sky Infrastructure — Terraform + Docker + Yandex Cloud

Итоговый проект по модулям **«Виртуализация и контейнеризация»** и **«Облачная инфраструктура. Terraform»**.

Развёртывание web-приложения в Yandex Cloud с использованием Infrastructure as Code (Terraform), Docker и Docker Compose.

---

## 📋 Содержание

- [Архитектура](#-архитектура)
- [Структура репозитория](#-структура-репозитория)
- [Что создаётся](#-что-создаётся)
- [Требования](#-требования)
- [Развёртывание](#-развёртывание)
- [Проверка работы](#-проверка-работы)
- [Скриншоты](#-скриншоты)
- [Проблемы и решения](#-проблемы-и-решения)

---

## 🏗 Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Yandex Cloud                            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  VPC: app-network (10.10.0.0/16)                     │  │
│  │                                                      │  │
│  │  ┌────────────────────┐   ┌────────────────────┐    │  │
│  │  │  Subnet A          │   │  Subnet B          │    │  │
│  │  │  10.10.1.0/24      │   │  10.10.2.0/24      │    │  │
│  │  │  ru-central1-a     │   │  ru-central1-b     │    │  │
│  │  │                    │   │                    │    │  │
│  │  │  ┌──────────────┐  │   │  ┌──────────────┐  │    │  │
│  │  │  │  VM app-vm   │  │   │  │ MySQL host 2 │  │    │  │
│  │  │  │  Docker +    │  │   │  │  (replica)   │  │    │  │
│  │  │  │  Node.js app │  │   │  └──────────────┘  │    │  │
│  │  │  └──────┬───────┘  │   │                    │    │  │
│  │  │         │          │   │                    │    │  │
│  │  │         │          │   │                    │    │  │
│  │  └─────────┼──────────┘   └────────────────────┘    │  │
│  │            │                                        │  │
│  │            ▼                                        │  │
│  │  ┌──────────────────────┐                           │  │
│  │  │  MySQL Cluster       │                           │  │
│  │  │  (master + replica)  │                           │  │
│  │  │  БД: app_db          │                           │  │
│  │  │  User: app_user      │                           │  │
│  │  └──────────────────────┘                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐      │
│  │  Container Registry  │    │  Object Storage      │      │
│  │  Образ приложения    │    │  Terraform state     │      │
│  └──────────────────────┘    └──────────────────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Компоненты:**
- **VPC + 2 подсети** в разных зонах доступности
- **MySQL кластер** (Managed Service) с master и replica
- **Container Registry** — хранилище Docker-образов
- **VM** с Docker и приложением, запускаемым через cloud-init
- **Object Storage** — удалённое хранение Terraform state

---

## 📁 Структура репозитория

```
.
├── app/                          # Исходники Node.js-приложения
│   ├── package.json
│   ├── server.js                 # Express-сервер + подключение к MySQL
│   └── public/
│       └── index.html            # Веб-страница
├── screenshots/                  # Скриншоты для отчёта
├── .dockerignore
├── .gitignore
├── Dockerfile                    # Мультисборка приложения
├── README.md                     # Этот файл
├── backend.tf                    # Terraform backend (S3)
├── cloud-init.yaml               # User-data для VM
├── docker-compose.yml            # Запуск приложения на VM
├── mysql.tf                      # MySQL кластер, БД, пользователь
├── network.tf                    # VPC, подсети, security groups
├── outputs.tf                    # Выходные значения
├── providers.tf                  # Провайдер Yandex Cloud
├── registry.tf                   # Container Registry
├── terraform.tfvars.example      # Шаблон переменных
├── variables.tf                  # Описание переменных
└── vm.tf                         # Виртуальная машина + сервисный аккаунт
```

---

## 🎯 Что создаётся

| Ресурс | Имя | Назначение |
|---|---|---|
| VPC | `app-network` | Основная сеть |
| Подсеть A | `app-subnet-a` | 10.10.1.0/24, `ru-central1-a` |
| Подсеть B | `app-subnet-b` | 10.10.2.0/24, `ru-central1-b` |
| Security Group | `vm-security-group` | Порты 22, 80, 443 для VM |
| Security Group | `mysql-security-group` | Порт 3306 из подсетей |
| MySQL кластер | `app-mysql-cluster` | 2 хоста, версия 8.0 |
| БД | `app_db` | База приложения |
| Пользователь | `app_user` | С правами `ALL` на `app_db` |
| Container Registry | `app-registry` | Реестр образов |
| Репозиторий | `<registry_id>/app` | Для образа приложения |
| Сервисный аккаунт | `vm-sa` | Для доступа VM к Registry |
| VM | `app-vm` | 2 vCPU, 2 GB RAM, Ubuntu 22.04 |

---

## 🛠 Требования

- **Terraform** ≥ 1.5.0
- **Docker** ≥ 20.10 + **Docker Compose** v2
- **Yandex Cloud CLI** (`yc`)
- **Node.js** ≥ 20 (для локальной сборки, опционально)
- Аккаунт в Yandex Cloud с активным биллингом
- SSH-ключ для доступа к VM

---

## 🚀 Развёртывание

### 1. Клонирование репозитория

```bash
git clone https://github.com/michaelkoch51/sky-infrastr-terraform.git
cd sky-infrastr-terraform
```

### 2. Настройка Yandex Cloud CLI

```bash
yc init
```

### 3. Создание сервисного аккаунта для Terraform

```bash
yc iam service-account create --name terraform-sa

yc resource-manager folder add-access-binding <FOLDER_ID> \
  --role editor \
  --service-account-id <SA_ID>

yc resource-manager folder add-access-binding <FOLDER_ID> \
  --role resource-manager.admin \
  --service-account-id <SA_ID>

yc iam key create \
  --service-account-id <SA_ID> \
  --output ~/sa-key.json

yc iam access-key create --service-account-id <SA_ID>
```

### 4. Создание S3-бакета для Terraform state

```bash
yc storage bucket create --name <BUCKET_NAME>
yc storage bucket update --name <BUCKET_NAME> --versioning versioning-enabled
```

### 5. Настройка переменных

```bash
cp terraform.tfvars.example terraform.tfvars
```

Заполнить `terraform.tfvars`:

```hcl
cloud_id     = "b1g..."
folder_id    = "b1g..."
default_zone = "ru-central1-a"
sa_key_file  = "/Users/username/sa-key.json"
db_password  = "YourStrongPassword123"
```

Создать `~/.secrets/backend.hcl`:

```hcl
access_key = "YCAJE..."
secret_key = "YCM..."
```

### 6. Инициализация Terraform

```bash
terraform init -backend-config=$HOME/.secrets/backend.hcl
```

### 7. Сборка и пуш Docker-образа

```bash
# Настройка Docker для работы с Yandex Container Registry
yc container registry configure-docker

# Сборка образа
docker build -t cr.yandex/<REGISTRY_ID>/app:latest .

# Пуш в Registry
docker push cr.yandex/<REGISTRY_ID>/app:latest
```

### 8. Развёртывание инфраструктуры

```bash
terraform plan
terraform apply
```

**Время развёртывания:** ~15 минут (MySQL кластер создаётся долго).

### 9. Проверка

После `apply` Terraform выведет IP:

```
Outputs:
vm_public_ip = "51.250.77.45"
```

**Открой в браузере:** `http://51.250.77.45`

---

## ✅ Проверка работы

### Приложение

Открой в браузере:
```
http://<vm_public_ip>
```

Должна открыться страница с:
- ✅ Статусом подключения к MySQL
- Версией MySQL
- Временем сервера БД
- Количеством таблиц

### SSH на VM

```bash
ssh ubuntu@<vm_public_ip>
```

### Проверка Docker

```bash
docker ps
docker logs terraform-app
```

### Проверка MySQL

```bash
# Список хостов
yc managed-mysql host list --cluster-id <CLUSTER_ID>

# Подключение с VM
mysql -h <FQDN> -u app_user -p app_db
```

---

## 📸 Скриншоты

### 1. Terraform apply — успешное создание инфраструктуры

![Terraform apply](screenshots/01-terraform-apply.png)

### 2. Виртуальная машина создана

![VM list](screenshots/02-vm-list.png)

### 3. MySQL кластер создан

![MySQL cluster](screenshots/03-mysql-cluster.png)

### 4. Container Registry с образом

![Registry](screenshots/04-registry.png)

### 5. Cloud-init выполнен, Docker работает

![Docker ps](screenshots/05-docker-ps.png)

### 6. Приложение работает в браузере

![App](screenshots/06-app-browser.png)

### 7. Структура репозитория на GitHub

![Repo](screenshots/07-github-repo.png)

---

## 🐛 Проблемы и решения

### Ошибка: `PermissionDenied` при создании IAM-binding

**Причина:** у сервисного аккаунта Terraform не хватает прав на управление IAM.

**Решение:**
```bash
yc resource-manager folder add-access-binding <FOLDER_ID> \
  --role resource-manager.admin \
  --service-account-id <TERRAFORM_SA_ID>

yc container registry add-access-binding <REGISTRY_ID> \
  --role container-registry.admin \
  --service-account-id <TERRAFORM_SA_ID>
```

### Ошибка: `Validation error: roles must be >= 1`

**Причина:** у пользователя MySQL не указана роль.

**Решение:** в `mysql.tf` добавить `roles = ["ALL"]` в блок `permission`.

### Ошибка: `npm ci` не находит `package-lock.json`

**Причина:** `npm ci` требует lock-файл.

**Решение:** заменить в `Dockerfile`:
```dockerfile
RUN npm ci --only=production
```
на:
```dockerfile
RUN npm install --omit=dev
```

### Приложение не открывается после `apply`

**Причина:** cloud-init ещё работает (установка Docker занимает 3-5 минут).

**Решение:** подождать 5-7 минут, потом проверить:
```bash
ssh ubuntu@<IP>
sudo cloud-init status
sudo tail -50 /var/log/cloud-init-output.log
docker ps
```

### Cloud-init не запускается при изменении `user-data`

**Причина:** cloud-init работает только при **первом** запуске VM.

**Решение:** принудительно пересоздать VM:
```bash
terraform apply -replace=yandex_compute_instance.app_vm
```

---

## 🔐 Безопасность

- ✅ Удалённый Terraform state в Object Storage
- ✅ Секреты не коммитятся в Git (`.gitignore`)
- ✅ Отдельные сервисные аккаунты для Terraform и VM
- ✅ VM имеет только право `container-registry.images.puller`
- ✅ MySQL доступен только из подсетей приложения

**TODO (доп. задание):**
- [ ] Хранение пароля БД в Yandex LockBox
- [ ] Statelocking через YDB

---

## 📚 Полезные ссылки

- [Terraform Yandex Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)
- [Yandex Cloud Documentation](https://cloud.yandex.ru/docs)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Cloud-init Documentation](https://cloud-init.io/)

---

## 👤 Автор

**Michael Kochnev**
- GitHub: [@michaelkoch51](https://github.com/michaelkoch51)

---

## 📝 Лицензия

Учебный проект. Свободное использование в образовательных целях.
