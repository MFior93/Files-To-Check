# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "d5c73fb6-3e1a-4942-92d5-6acf6d976b93"
    client_id       = "f844042d-f59e-48ac-8270-1e8291a4201f"
    client_secret   = "d4b53d76-5600-4223-9740-345d55fe0867"
    tenant_id       = "0fbcd888-3f1c-411d-b2f8-dac6097b0b3b"
}

# Create a resource group
resource "azurerm_resource_group" "rg-3tier" {
 name     = "3tier-app-rg"
 location = "westeurope"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet-3tier" {
    name                = "virtualn"
    address_space       = ["10.1.2.0/23"]
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.rg-3tier.name

}

# Create subnet
resource "azurerm_subnet" "subnet-1" {
    name                 = "subnet-1-front"
    resource_group_name  = azurerm_resource_group.rg-3tier.name
    virtual_network_name = azurerm_virtual_network.vnet-3tier.name
    address_prefix       = "10.1.2.0/24"
}

resource "azurerm_subnet" "subnet-2" {
    name                 = "subnet-2-back"
    resource_group_name  = azurerm_resource_group.rg-3tier.name
    virtual_network_name = azurerm_virtual_network.vnet-3tier.name
    address_prefix       = "10.1.3.0/24"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg-3tier-back" {
    name                = "nsg-1-front"
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.rg-3tier.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_security_group" "nsg-3tier-front" {
    name                = "nsg-2-back"
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.rg-3tier.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "RDP"
        priority                   = 320
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTPS"
        priority                   = 340
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTP"
        priority                   = 360
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create public IPs
resource "azurerm_public_ip" "pubip-1-front" {
    name                         = "pubip-1-front"
    location                     = "westeurope"
    resource_group_name          = azurerm_resource_group.rg-3tier.name
    allocation_method            = "Static"
    domain_name_label            = "front-vm-1"
}

resource "azurerm_public_ip" "pubip-2-front" {
    name                         = "pubip-2-front"
    location                     = "westeurope"
    resource_group_name          = azurerm_resource_group.rg-3tier.name
    allocation_method            = "Static"
    domain_name_label            = "front-vm-2"
}

resource "azurerm_public_ip" "pubip-3-loadbalancer-external" {
    name                         = "pubip-3-loadbalancer-external"
    location                     = "westeurope"
    resource_group_name          = azurerm_resource_group.rg-3tier.name
    allocation_method            = "Static"
    domain_name_label            = "mat-new-website"
}
    
# Create network interface
resource "azurerm_network_interface" "networkinterface1" {
    name                      = "nic-1-front"
    location                  = "westeurope"
    resource_group_name       = azurerm_resource_group.rg-3tier.name
    network_security_group_id = azurerm_network_security_group.nsg-3tier-front.id

    ip_configuration {
        name                          = "nic-conf-1-front"
        subnet_id                     = azurerm_subnet.subnet-1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.2.4"
        public_ip_address_id          = azurerm_public_ip.pubip-1-front.id
    }
}
resource "azurerm_network_interface" "networkinterface2" {
    name                      = "nic-2-front"
    location                  = "westeurope"
    resource_group_name       = azurerm_resource_group.rg-3tier.name
    network_security_group_id = azurerm_network_security_group.nsg-3tier-front.id

    ip_configuration {
        name                          = "nic-conf-2-front"
        subnet_id                     = azurerm_subnet.subnet-1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.2.5"
        public_ip_address_id          = azurerm_public_ip.pubip-2-front.id
    }
}
resource "azurerm_network_interface" "networkinterface3" {
    name                      = "nic-1-back"
    location                  = "westeurope"
    resource_group_name       = azurerm_resource_group.rg-3tier.name
    network_security_group_id = azurerm_network_security_group.nsg-3tier-back.id

    ip_configuration {
        name                          = "nic-conf-1-back"
        subnet_id                     = azurerm_subnet.subnet-2.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.3.4"
    }
}
resource "azurerm_network_interface" "networkinterface4" {
    name                      = "nic-2-back"
    location                  = "westeurope"
    resource_group_name       = azurerm_resource_group.rg-3tier.name
    network_security_group_id = azurerm_network_security_group.nsg-3tier-back.id

    ip_configuration {
        name                          = "nic-conf-2-back"
        subnet_id                     = azurerm_subnet.subnet-2.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.3.5"
    }
}

# Creating availibality set 
resource "azurerm_availability_set" "availabilityset-front" {
  name                                         = "availset-front"
  location                                     = azurerm_resource_group.rg-3tier.location
  resource_group_name                          = azurerm_resource_group.rg-3tier.name
  platform_update_domain_count                 = 5
  platform_fault_domain_count                  = 2
  managed                                      = "true"
}
resource "azurerm_availability_set" "availabilityset-back" {
  name                                         = "availset-back"
  location                                     = azurerm_resource_group.rg-3tier.location
  resource_group_name                          = azurerm_resource_group.rg-3tier.name
  platform_update_domain_count                 = 5
  platform_fault_domain_count                  = 2
  managed                                      = "true"
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diagnostics-storage" {
    name                        = "3tierdiag"
    resource_group_name         = azurerm_resource_group.rg-3tier.name
    location                    = "westeurope"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

#CREATING VM's and DB -----------------------------------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine" "webserver-1" {
  name                  = "vm-1-front"
  location              = azurerm_resource_group.rg-3tier.location
  resource_group_name   = azurerm_resource_group.rg-3tier.name
  network_interface_ids = ["${azurerm_network_interface.networkinterface1.id}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.availabilityset-front.id}"

storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

storage_os_disk {
    name              = "webserver1-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

os_profile {
    computer_name      = "vm-1-front"
    admin_username     = "mateuszadm"
    admin_password     = "Testpassword123"
  }

os_profile_windows_config {
  }

}

resource "azurerm_virtual_machine" "webserver-2" {
  name                  = "vm-2-front"
  location              = azurerm_resource_group.rg-3tier.location
  resource_group_name   = azurerm_resource_group.rg-3tier.name
  network_interface_ids = ["${azurerm_network_interface.networkinterface2.id}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.availabilityset-front.id}"

storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

storage_os_disk {
    name              = "webserver2-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

os_profile {
    computer_name      = "vm-2-front"
    admin_username     = "mateuszadm"
    admin_password     = "Testpassword123"
  }

os_profile_windows_config {
  }

}

resource "azurerm_virtual_machine" "backserver-1" {
    name                  = "vm-1-back"
    location              = "westeurope"
    resource_group_name   = azurerm_resource_group.rg-3tier.name
    network_interface_ids = ["${azurerm_network_interface.networkinterface3.id}"]
    vm_size               = "Standard_DS1_v2"
    availability_set_id   = "${azurerm_availability_set.availabilityset-back.id}"

    storage_os_disk {
        name              = "backserver1-os"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "vm-1-back"
        admin_username = "mateuszadm"
        admin_password = "Testpassword123"
    }

    os_profile_linux_config {
    disable_password_authentication = false
  }


    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.diagnostics-storage.primary_blob_endpoint}"
    }
}

resource "azurerm_virtual_machine" "backserver-2" {
    name                  = "vm-2-back"
    location              = "westeurope"
    resource_group_name   = azurerm_resource_group.rg-3tier.name
    network_interface_ids = ["${azurerm_network_interface.networkinterface4.id}"]
    vm_size               = "Standard_DS1_v2"
    availability_set_id   = "${azurerm_availability_set.availabilityset-back.id}"

    storage_os_disk {
        name              = "backserver2-os"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "vm-2-back"
        admin_username = "mateuszadm"
        admin_password = "Testpassword123"
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.diagnostics-storage.primary_blob_endpoint}"
    }
}

resource "azurerm_sql_server" "sql-s-1" {
  name                         = "mat-sql-server-1"
  resource_group_name          = azurerm_resource_group.rg-3tier.name
  location                     = "westeurope"
  version                      = "12.0"
  administrator_login          = "mateuszadm"
  administrator_login_password = "Testpassword123"
}

resource "azurerm_sql_database" "sql-d-1" {
  name                = "mat-sql-database-1"
  resource_group_name = azurerm_resource_group.rg-3tier.name
  location            = azurerm_resource_group.rg-3tier.location
  server_name         = azurerm_sql_server.sql-s-1.name
}

resource "azurerm_sql_server" "sql-s-2" {
  name                         = "mat-sql-server-2"
  resource_group_name          = azurerm_resource_group.rg-3tier.name
  location                     = "westeurope"
  version                      = "12.0"
  administrator_login          = "mateuszadm"
  administrator_login_password = "Testpassword123"
}

resource "azurerm_sql_database" "sql-d-2" {
  name                = "mat-sql-database-2"
  resource_group_name = azurerm_resource_group.rg-3tier.name
  location            = azurerm_resource_group.rg-3tier.location
  server_name         = azurerm_sql_server.sql-s-2.name
}


#Load Balancers -------------------------------------------------------------------


resource "azurerm_lb" "external-lb" {
  name                = "external-lb"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg-3tier.name

  frontend_ip_configuration {
    name                 = "pub-ip-external"
    public_ip_address_id = azurerm_public_ip.pubip-3-loadbalancer-external.id
  }
}

resource "azurerm_lb_backend_address_pool" "external-pool" {
  resource_group_name = azurerm_resource_group.rg-3tier.name
  loadbalancer_id     = azurerm_lb.external-lb.id
  name                = "backendpool-external"
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = azurerm_resource_group.rg-3tier.name
  loadbalancer_id                = azurerm_lb.external-lb.id
  name                           = "websiteup"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "pub-ip-external"
}

#internal LB ------------------------------------------------
resource "azurerm_lb" "internal-lb" {
  name                = "internal-lb"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg-3tier.name

  frontend_ip_configuration {
    name                          = "Internal-lb-ip"
    subnet_id                     = azurerm_subnet.subnet-2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.3.6"
  }
}

resource "azurerm_lb_backend_address_pool" "internal-pool" {
  resource_group_name = azurerm_resource_group.rg-3tier.name
  loadbalancer_id     = azurerm_lb.internal-lb.id
  name                = "backendpool-internal"
}