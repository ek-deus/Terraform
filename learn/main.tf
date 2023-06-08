# создание провайдера

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
#     backend "s3" {
#     endpoint   = "storage.yandexcloud.net"
#     bucket     = "<имя бакета>"
#     region     = "ru-central1"
#     key        = "<путь к файлу состояния в бакете>/<имя файла состояния>.tfstate"
#     access_key = "<идентификатор статического ключа>"
#     secret_key = "<секретный ключ>"
#       shared_credentias_file - его будем использовать

#     skip_region_validation      = true
#     skip_credentials_validation = true
#   } это для сохранения = "storage.key" файла состояния (terraform.tfstate) в зранилизе S3 
}

provider "yandex" {
#   token = <OAuth> - заменим этот способ аутентификации на service_account_key_file
  service_account_key_file = "key.json"
  cloud_id =
  folder_id =
  zone = "<зона доступности по умолчанию>"
}

# source — глобальный адрес источника провайдера.
# required_version — минимальная версия Terraform, с которой совместим провайдер.
# provider — название провайдера.
# zone — зона доступности, в которой по умолчанию будут создаваться все облачные ресурсы.

# выполняем в терминале 
```bash
yc iam key create --folder-name my-folder --service-account-name my-robot --output key.json
```
# my-robot - это меняем на название нашего аккаунта

# создаем сеть

resource "yandex_vpc_network" "mynet" {
  name = "mynetwork"
}

# создаем подсеть

resource "yandex_vpc_subnet" "mysubnet-a" {
  v4_cidr_blocks = ["10.11.0.0/16"]
#   zone           = "ru-central1-a" - тут она уже  не нужна мы ее указали раньше
  network_id     = yandex_vpc_network.mynet.id
}

#добаваляем что бы  внешний ip не менялся после рестарта

resource "yandex_vpc_address" "addr" {
  name = "exampleAddress"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

# создаем  "машинку"

resource "yandex_compute_instance" "default" {
  name        = "test"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "image_id"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.foo.id}"
    nat = true # делаем nat, а то у нашей "машинки" нет инетта - получаем публичный IP
    nat_ip_address = yandex_vpc_subnet.ek-ip.external_ipv4_address.0.address # ссылаемся на ip который нам дали
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    user-data": "${file("<путь к файлу>.meta.txt")}"  #только в яндексе так можно предавать в ВМ скрит на исполненне 
    
  }
}

output "external_ip" {
value = yandex_vpc_subnet.ek-ip.external_ipv4_address.0.address
}

outpuut "external_ip-2" {
value = yandex_computere_instance.ekdeus.network)interface.0.nat_ip_address
}

#  image_id = "image_id" - это берем из https://cloud.yandex.ru/marketplace
#  image_id = fd8ps4vdhf5hhuj8obp2
#  или yc compute image list --folder-id standard-images | grep ubuntu

