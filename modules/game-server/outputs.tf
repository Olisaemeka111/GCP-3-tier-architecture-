output "public_ip" {
  description = "The static public IP of the game server."
  value       = google_compute_address.this.address
}

output "url" {
  description = "The WorkAdventure URL (via sslip.io)."
  value       = "https://${google_compute_address.this.address}.sslip.io"
}

output "instance_name" {
  description = "The game server instance name."
  value       = google_compute_instance.this.name
}

output "zone" {
  description = "The game server zone."
  value       = google_compute_instance.this.zone
}
