# create http redirector droplet
resource "digitalocean_droplet" "redir-http" {
  image  = "ubuntu-18-04-x64"
  name   = "redir-http"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  ssh_keys = ["${digitalocean_ssh_key.dossh.id}"]

  provisioner "remote-exec" {
    inline = [
        # environment
        "apt update",
        "apt-get -y install socat",
        "echo \"@reboot root socat TCP4-LISTEN:80,fork TCP4:${digitalocean_droplet.c2-http.ipv4_address}:80\" >> /etc/cron.d/mdadm",
        "echo \"@reboot root socat TCP4-LISTEN:443,fork TCP4:${digitalocean_droplet.c2-http.ipv4_address}:443\" >> /etc/cron.d/mdadm",
        
        # http/s traffic redirectors
        "socat TCP4-LISTEN:80,fork TCP4:${digitalocean_droplet.c2-http.ipv4_address}:80 &",
        "socat TCP4-LISTEN:443,fork TCP4:${digitalocean_droplet.c2-http.ipv4_address}:443 &",
        "shutdown -r"
    ]
  }
}


# configure http c2 firewall
resource "digitalocean_firewall" "redir-http" {
    name = "redir-http"

    droplet_ids = ["${digitalocean_droplet.redir-http.id}"]

    inbound_rule = [
    {
        protocol = "tcp"
        port_range = "22"
        source_addresses = ["${var.operatorIP}"]
    },
    {
        protocol = "tcp"
        port_range = "80"
        source_addresses = ["0.0.0.0/0"]
    },
    {
        protocol = "tcp"
        port_range = "443"
        source_addresses = ["0.0.0.0/0"]
    },
    {
        protocol = "tcp"
        port_range = "50050"
        source_addresses = ["${var.operatorIP}"]
    }
    ]

    outbound_rule = [
    {
        protocol = "udp"
        port_range = "53"
        destination_addresses = ["0.0.0.0/0"]
    },
    {
        protocol = "tcp"
        port_range = "80"
        destination_addresses = ["0.0.0.0/0"]
    },
    {
        protocol = "tcp"
        port_range = "443"
        destination_addresses = ["0.0.0.0/0"]
    }
    ]
}