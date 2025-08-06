resource "aws_cognito_user_pool" "knowledge_base_website" {
    name = local.project_name
    username_attributes = ["email"]
    auto_verified_attributes = ["email"]
    password_policy {
        minimum_length = 8
        require_uppercase = true
        require_lowercase = true
        require_numbers = true
        require_symbols = true
    }
}

resource "aws_cognito_user_pool_client" "knowledge_base_website" {
    name = local.project_name
    user_pool_id = aws_cognito_user_pool.knowledge_base_website.id
}

resource "aws_cognito_user" "knowledge_base_website" {
    user_pool_id = aws_cognito_user_pool.knowledge_base_website.id
    username = "testuser@example.com"
    message_action = "SUPPRESS"
    password = "TestUser123!"
    enabled = true
    attributes = {
        email = "testuser@example.com"
    }

    depends_on = [aws_cognito_user_pool.knowledge_base_website]

}