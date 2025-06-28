# ------ IAM -------------------
resource "aws_iam_role" "test_role" {
  name = "s3_event_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.test_bucket.id}/*"
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}


resource "aws_iam_role_policy_attachment" "policy_attachement" {
  role       = aws_iam_role.test_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}




# ----- LAMBDA ------------------
data "archive_file" "source_code" {
  type        = "zip"
  source_dir  = "./handler"
  output_path = "./handler.zip"
}

resource "aws_lambda_function" "upload_event" {
  function_name    = "upload_event"
  source_code_hash = data.archive_file.source_code.output_base64sha256
  role             = aws_iam_role.test_role.arn
  filename         = "handler.zip"
  runtime          = "python3.9"
  handler          = "handler.handler"
}


# ------------ S3 -----------------
resource "aws_s3_bucket" "test_bucket" {
  bucket = "mylocalstackbucket"
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.test_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.upload_event.arn
    events              = ["s3:ObjectCreated:*"]
  }

}
