# ==========================================
# 3. AMAZON DYNAMODB TABLE
# ==========================================

resource "aws_dynamodb_table" "retail_table" {
  name         = "bedrock-retail-products"
  billing_mode = "PAY_PER_REQUEST" # Serverless on-demand scaling
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = {
    Name = "bedrock-dynamodb-table"
  }
}