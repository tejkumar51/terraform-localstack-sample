provider "aws" {
  region = "us-east-1"
  access_key = "123"
  secret_key = "xyz"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  skip_metadata_api_check = true
  s3_force_path_style = true
  endpoints {
    s3 = "http://localhost:4572"
    dynamodb = "http://localhost:4569"
    apigateway = "http://localhost:4567"
  }
}

resource "aws_s3_bucket" "b" {
  #bucket = "demo-bucket-terraform"
  #acl    = "public-read"
    bucket = "sample-bucket"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "c" {
  name         = "sample-dynamodb_table"
  hash_key     = "request_id"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "request_id"
    type = "S"
  }
}

/*
resource "aws_api_gateway_rest_api" "example" {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}
*/

resource "aws_api_gateway_rest_api" "the" {
  name = "example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "the" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  parent_id   = aws_api_gateway_rest_api.the.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_model" "the" {
  rest_api_id  = aws_api_gateway_rest_api.the.id
  name         = "POSTExampleRequestModelExample"
  description  = "A JSON schema"
  content_type = "application/json"
  schema       = file("${path.module}/request_schemas/post_example.json")
}

/*
resource "aws_api_gateway_request_validator" "the" {
  name                        = "POSTExampleRequestValidator"
  rest_api_id                 = aws_api_gateway_rest_api.the.id
  validate_request_body       = true
  validate_request_parameters = false
}
*/
resource "aws_api_gateway_method" "the" {
  rest_api_id          = aws_api_gateway_rest_api.the.id
  resource_id          = aws_api_gateway_resource.the.id
  authorization        = "NONE"
  http_method          = "POST"

  request_models = {
    "application/json" = aws_api_gateway_model.the.name
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  resource_id = aws_api_gateway_resource.the.id
  http_method = aws_api_gateway_method.the.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "the" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  resource_id = aws_api_gateway_method.the.resource_id
  http_method = aws_api_gateway_method.the.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "the" {
  depends_on  = [aws_api_gateway_integration.the]
  rest_api_id = aws_api_gateway_rest_api.the.id
  resource_id = aws_api_gateway_resource.the.id
  http_method = aws_api_gateway_method.the.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
}