terraform {
  backend "s3" {
    bucket       = "dolo-dempo"
    key          = "state/dev/spring-boot-application/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true ###dynamodb_table = "terraform-state"
  }
}
