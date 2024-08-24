terraform {
  required_providers {
    azuredevops = {
      source                              = "microsoft/azuredevops"
      version                             = "1.2.0"
    }
  }
}

terraform {
  backend "azurerm" {
  }
}

resource "azurerm_service_plan" "ServicesPlan" {
  name                                      = var.WEBAPP_PLAN_NAME
  resource_group_name                       = var.RG_NAME
  location                                  = var.LOCATION
  os_type                                   = var.OS_TYPE
  sku_name                                  = var.SKU_NAME
}

resource "azurerm_linux_web_app" "WebApp" {
  name                                      = var.WEB_APP_NAME
  resource_group_name                       = var.RG_NAME
  location                                  = azurerm_service_plan.ServicesPlan.location
  service_plan_id                           = azurerm_service_plan.ServicesPlan.id

  site_config {
    always_on                               = true
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "true"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "docker_registry_url"                   = var.DOCKER_REGISTRY_SERVER_URL
    "docker_registry_username"              = var.DOCKER_REGISTRY_SERVER_USERNAME
    "docker_registry_password"              = var.DOCKER_REGISTRY_SERVER_PASSWORD
  }
}

output "webapp_name" {
  value = azurerm_linux_web_app.WebApp.name
}

### To Create the Azure Auto Scale based on the CPU Percentage ################
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                                      = var.APP_AUTOSCALE
  resource_group_name                       = azurerm_service_plan.ServicesPlan.resource_group_name
  location                                  = azurerm_service_plan.ServicesPlan.location
  target_resource_id                        = azurerm_service_plan.ServicesPlan.id

  profile {
    name = "defaultProfile"
    capacity {
      default                               = 1
      minimum                               = 1
      maximum                               = 2
    }
    rule {
      metric_trigger {
        metric_name                         = "CpuPercentage"
        metric_resource_id                  = azurerm_service_plan.ServicesPlan.id
        time_grain                          = "PT1M"
        statistic                           = "Average"
        time_window                         = "PT5M"
        time_aggregation                    = "Average"
        operator                            = "GreaterThan"
        threshold                           = 5
      }

      scale_action {
        direction                           = "Increase"
        type                                = "ChangeCount"
        value                               = "1"
        cooldown                            = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name                         = "CpuPercentage"
        metric_resource_id                  = azurerm_service_plan.ServicesPlan.id
        time_grain                          = "PT1M"
        statistic                           = "Average"
        time_window                         = "PT5M"
        time_aggregation                    = "Average"
        operator                            = "LessThan"
        threshold                           = 80
      }
      scale_action {
        direction                           = "Decrease"
        type                                = "ChangeCount"
        value                               = "1"
        cooldown                            = "PT1M"
      }
    }
  }
  ### To Send the Alert ################
  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
      custom_emails                         = [var.CUSTOM_EMAILS]
    }
  }
}