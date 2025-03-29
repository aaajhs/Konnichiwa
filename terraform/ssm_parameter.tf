/* ------------------------------ SSM Parameter ----------------------------- */

resource "aws_ssm_parameter" "api_key" {
  type = "SecureString"

  name  = local.secret_name
  value = file(local.secret_location)
}
