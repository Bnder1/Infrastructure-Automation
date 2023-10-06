output "outputs" {
  value = [
    "phishing ${cloudflare_record.phishing-a1.name}.${var.domain-c2} - ${digitalocean_droplet.phishing.ipv4_address}", 
    "phishing redirector a1 ${digitalocean_record.phishing-rdr-a0.name}${var.domain-rdir} - ${digitalocean_droplet.phishing-rdr.ipv4_address}", 
    "phishing redirector a2 ${digitalocean_record.phishing-rdr-a1.name}.${var.domain-rdir} - ${digitalocean_droplet.phishing-rdr.ipv4_address}", 
    "phishing smtp relay ${digitalocean_record.phishing-rdr-mail-a1.name}.${var.domain-rdir} - ${digitalocean_droplet.phishing-rdr.ipv4_address}",

    "To finalise the infrastructure, run ./finalize.sh and update the DNS DKIM in DigitalOcean for ${var.domain-rdir} which the script will provide."
    ]
}
