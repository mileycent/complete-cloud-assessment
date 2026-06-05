# Generate a cryptographically secure random password for database administration
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create the Secret metadata wrapper in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "project-bedrock/db-credentials"
  recovery_window_in_days = 0 # Forces deletion during environment tear-down scenarios
}

# Inject the generated password string into the secret value block securely
resource "aws_secretsmanager_secret_version" "db_pass_val" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = random_password.db_password.result
}