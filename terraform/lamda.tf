variable "student_id" {
  type        = string
  default     = "alt-soe-025-3682" # Maps your distinct tracking suffix parameter
}

# ==========================================
# 1. SERVERLESS IAM ROLES & POLICY DRIVERS
# ==========================================

resource "aws_iam_role" "lambda_exec" {
  name = "bedrock-asset-processor-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Attach core managed policy giving your function authority to create logs inside CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==========================================
# 2. PRIVATE S3 ASSET STORAGE CONFIGURATION
# ==========================================

resource "aws_s3_bucket" "assets" {
  bucket        = "bedrock-assets-${var.student_id}"
  force_destroy = true # Aids clean destruction during grading tear-downs
}

resource "aws_s3_bucket_public_access_block" "assets_privacy" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==========================================
# 3. LAMBDA ENGINE ARCHIVE SETUP & COMPILATION
# ==========================================

# Dynamically archives the execution script code from the root lambda directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.py"
  output_path = "${path.module}/../lambda/lambda_function_payload.zip"
}

resource "aws_lambda_function" "processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "bedrock-asset-processor"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 15
}

# ==========================================
# 4. S3 NOTIFICATION TRIGGERS & ACCESS RULES
# ==========================================

# Explicit permission setting giving the S3 Bucket resource authority to invoke the function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.assets.arn
}

# Registers the real-time event handler subscription directly inside the target pipeline bucket path
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.assets.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}