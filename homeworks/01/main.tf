terraform {
  required_providers {

    docker = {
      source  = "kreuzwerker/docker"
    }

    random = {
      source = "hashicorp/random"
    }

  }

  required_version = ">=1.12.0"
}

provider "docker" {
  host = "ssh://yc-user@158.160.126.191"
}

resource "random_password" "mysql_root" {
  length  = 16
  special = false
}

resource "random_password" "mysql_user" {
  length  = 16
  special = false
}

resource "docker_image" "mysql" {
  name         = "mysql:8"
  keep_locally = true
}

resource "docker_container" "mysql" {

  name  = "mysql_wordpress"
  image = docker_image.mysql.image_id

  ports {
    internal = 3306
    external = 3306
    ip       = "127.0.0.1"
  }

  env = [
    "MYSQL_ROOT_PASSWORD=${random_password.mysql_root.result}",
    "MYSQL_DATABASE=wordpress",
    "MYSQL_USER=wordpress",
    "MYSQL_PASSWORD=${random_password.mysql_user.result}",
    "MYSQL_ROOT_HOST=%"
  ]

}
