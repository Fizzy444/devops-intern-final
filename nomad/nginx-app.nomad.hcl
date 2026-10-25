variable "image_repo" {
  type    = string
  default = "ghcr.io/Fizzy444/devops-intern-final"
}

variable "image_tag" {
  type = string
}

job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "2m"
    progress_deadline = "5m"
    health_check      = "checks"
    auto_revert       = true
  }

  group "web" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "delay"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "10m"
      unlimited      = true
    }

    service {
      name     = "nginx-app"
      port     = "http"
      provider = "consul"
      tags     = ["nginx", "web"]

      check {
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "${var.image_repo}:${var.image_tag}"
        ports = ["http"]

        labels {
          logging = "promtail"
          service = "nginx-app"
        }
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
