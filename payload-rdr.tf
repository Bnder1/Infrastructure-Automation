# create payload redirector droplet
resource "digitalocean_droplet" "payload-rdr" {
  image  = "ubuntu-18-04-x64"
  name   = "${var.domain-rdir}"
  # name   = "payload-rdr"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  ssh_keys = ["${digitalocean_ssh_key.dossh.id}"]

  provisioner "remote-exec" {
    inline = [
      # environment
      "apt update",
      # "export DEBIAN_FRONTEND=noninteractive; apt-get -y install socat postfix opendkim opendkim-tools",
      "export DEBIAN_FRONTEND=noninteractive; apt-get -y install socat postfix opendkim opendkim-tools",
      "echo ${var.domain-rdir} > /etc/mailname",
      # "sed -i 's/myhostname = ${digitalocean_droplet.payload-rdr.name}/myhostname = ${var.domain-rdir}/' /etc/postfix/main.cf",
      # "sed -i 's/127.0.0.0\\/8/${digitalocean_droplet.payload.ipv4_address}/' /etc/postfix/main.cf",
      "postconf -e myhostname=${var.domain-rdir}",
      # "postconf -e mynetworks=${digitalocean_droplet.payload.ipv4_address}",
      "postconf -e milter_protocol=2",
      "postconf -e milter_default_action=accept",
      "postconf -e smtpd_milters=inet:localhost:12345",
      "postconf -e non_smtpd_milters=inet:localhost:12345",
      "postconf -e mydestination=\"${var.domain-rdir}, $myhostname, localhost.localdomain, localhost\"",
      "postconf -e mynetworks=\"127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 ${digitalocean_droplet.payload.ipv4_address}\"",
      "mkdir -p /etc/opendkim/keys/${var.domain-rdir}",
      "cd /etc/opendkim/keys/${var.domain-rdir}; opendkim-genkey -t -s mail -d ${var.domain-rdir} && tr -d \"\\n\\t\\\" \" < mail.txt | cut -d\"(\" -f2 | cut -d \")\" -f1 > dkim.txt; sudo chown opendkim:opendkim mail.private",
      "echo mail._domainkey.${var.domain-rdir} ${var.domain-rdir}:mail:/etc/opendkim/keys/${var.domain-rdir}/mail.private > /etc/opendkim/KeyTable",
      "echo *@${var.domain-rdir} mail._domainkey.${var.domain-rdir} > /etc/opendkim/SigningTable",
      "echo \"SOCKET=\"inet:12345@localhost\"\" >> /etc/default/opendkim",
      "echo \"@reboot root socat TCP4-LISTEN:80,fork TCP4:${digitalocean_droplet.payload.ipv4_address}:80\" >> /etc/cron.d/mdadm",
      "echo \"@reboot root socat TCP4-LISTEN:443,fork TCP4:${digitalocean_droplet.payload.ipv4_address}:443\" >> /etc/cron.d/mdadm",
# this is broken for some reason
      "echo -e \"127.0.0.1\\nlocalhost\\n*.${var.domain-rdir}\\n${digitalocean_droplet.payload.ipv4_address}\" > /etc/opendkim/TrustedHosts"
    ]
  }

  provisioner "file" {
    source = "header_checks"
    destination = "/etc/postfix/header_checks"
  }

  provisioner "file" {
    source = "master.cf"
    destination = "/etc/postfix/master.cf"
  }

  provisioner "file" {
    source = "opendkim.conf"
    destination = "/etc/opendkim.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "postmap /etc/postfix/header_checks",
      "postfix reload",
      "service postfix restart; service opendkim restart"
      # "shutdown -r"
    ]
  }
}