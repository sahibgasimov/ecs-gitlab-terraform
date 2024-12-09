locals {
  vpc = {
    vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  }

  public_subnets  = data.terraform_remote_state.vpc.outputs.public_subnets
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
}
