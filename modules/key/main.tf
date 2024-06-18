#......................................ec2 key pair....................................

resource "aws_key_pair" "client_key" {
  key_name = "client key"
  public_key = "YOUR PUBLIC KEY PATH"
  
}