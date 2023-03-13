variable "SERVICE_DOMAIN" {
  description = "Domain for cloudflare tunnel"
  type        = string
}

variable "CLOUDFLARE_EMAIL" {
  description = "Email account for cloudflare tunnel"
  type        = string
}

variable "CLOUDFLARE_ACCOUNT_ID" {
  description = "value"
  type        = string
  default     = "59df3335cd13194b6e67b0b1116c1497"
}

variable "CLOUDFLARE_ZONE_ID" {
  description = "value"
  type        = string
  default     = "52517fa1f224d1db11d1090e90c5e303"
}

variable "CLOUDFLARE_TOKEN" {
  description = "API token for making changes to cloudflare tunnel"
  type        = string
}

variable "CLOUDFLARE_GOOGLE_CLIENT_ID" {
  description = "Google Client ID for accessing cloudflare tunnel"
  type        = string
}

variable "CLOUDFLARE_GOOGLE_CLIENT_SECRET" {
  description = "Google Client Secret for accessing cloudflare tunnel"
  type        = string
}

variable "CLOUDFLARE_ACCESS_EMAILS" {
  description = "Accepted email access list"
  type        = list(string)
}

variable "CLOUDFLARE_APPLICATIONS" {
  type = set(string)
  default = ["home", "listen", "read", "media", "connector", "git", "podgrab", "proxy", "queue", "ytdl", "git", "photos", "ssh", "ha", "monitoring", "prometheus", "browser", "printer"]
}