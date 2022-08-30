locals {
  resource_group_name = "rg-visualstudio-lab-june-dev"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKhIOHFOigOp0Ia9LbbqeuSdcGdqpKat9rFA77MfLjObNlm3erL3v3QY6+YPlQfYy8aTqTKz4GrjRtp84kfTrepLLN+WCSDyaD703F6wAdVYzfKKHx/FaArSHEnJ2ioe8+1BxnSaJziHW7hgEMXNOk7ooIvp3+DaI4K4XcNLrbA3FWkSAgB4xWhXl5LnCOS9iI9jlipBgt3FCQ9WruWl6YomwhtxWTsuog3wt5Jo5sXzF+n63Y/JUN0Ac+N4ya8kpj4yb/rB9w2geBPUMAh1JKIqXK8Z1VgfTEPw311UZmL8UyKhOzU2JspsRMItk6tCMdiTrxllh32Dq2q+T4nzsR vibi@cc-78a5471a-6bc896df5c-4tqzh"
  location = "canadacentral"
}

# Create virtual network
resource "azurerm_virtual_network" "lab_vnet" {
    name = "labVNET"
    address_space = ["10.250.252.0/24"]
    location = "${local.location}"
    resource_group_name = "${local.resource_group_name}"
}

resource "azurerm_subnet" "lab_subnet" {
    name = "labSUBNET"
    resource_group_name = "${local.resource_group_name}"
    virtual_network_name = "${azurerm_virtual_network.lab_vnet.name}"
    address_prefixes = ["10.250.252.0/26"]
}
  
# Create public IPs
resource "azurerm_public_ip" "lab_pip" {
    name = "labPIP"
    location = "${local.location}"
    resource_group_name = "${local.resource_group_name}"
    allocation_method = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "lab_nsg" {
    name = "labNSG"
    location = "${local.location}"
    resource_group_name = "${local.resource_group_name}"
    security_rule {
        name = "SSH"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

# Create network interface
resource "azurerm_network_interface" "lab_nic" {
    name = "labNIC"
    location = "${local.location}"
    resource_group_name = "${local.resource_group_name}"
    #network_security_group_id = "${azurerm_network_security_group.lab_nsg.id}"
    ip_configuration {
        name = "labNicConfiguration"
        subnet_id = "${azurerm_virtual_network.lab_vnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "${azurerm_public_ip.lab_pip.id}"
    }
}

resource "azurerm_network_interface_security_group_association" "assoc_nsg" {
  network_interface_id      = azurerm_network_interface.lab_nic.id
  network_security_group_id = azurerm_network_security_group.lab_nsg.id
}

# Create virtual machine
resource "azurerm_virtual_machine" "lab_vm" {
    name = "labVM"
    location = "${local.location}"
    resource_group_name = "${local.resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.lab_nic.id}"]
    vm_size = "Standard_B1ms"
    storage_os_disk {
        name = "labVMOSDISK"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Premium_LRS"
    }
    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04.0-LTS"
        version = "latest"
    }
    os_profile {
        computer_name = "labvm"
        admin_username = "labvmadmin"
    }
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/labvmadmin/.ssh/authorized_keys"
            key_data = "${local.public_key}"
        }
    }
}