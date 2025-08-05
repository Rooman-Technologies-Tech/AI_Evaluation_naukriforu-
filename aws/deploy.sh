#!/bin/bash

# AWS Deployment Script for Recruitment Portal
# This script sets up the complete infrastructure and deploys the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="recruitment-portal-stack"
ENVIRONMENT=${1:-development}
REGION=${2:-us-east-1}
DB_PASSWORD=${3:-"RecruitmentPortal123!"}

echo -e "${GREEN}🚀 Starting AWS Deployment for Recruitment Portal${NC}"
echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}Region: ${REGION}${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials are not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI and credentials verified${NC}"

# Create S3 bucket for CloudFormation templates
BUCKET_NAME="recruitment-portal-templates-$(date +%s)"
echo -e "${YELLOW}📦 Creating S3 bucket for templates: ${BUCKET_NAME}${NC}"
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

# Upload CloudFormation template
echo -e "${YELLOW}📤 Uploading CloudFormation template${NC}"
aws s3 cp hybrid-infrastructure.yaml s3://${BUCKET_NAME}/infrastructure.yaml

# Deploy CloudFormation stack
echo -e "${YELLOW}🏗️  Deploying CloudFormation stack${NC}"
aws cloudformation create-stack \
    --stack-name ${STACK_NAME} \
    --template-url https://${BUCKET_NAME}.s3.amazonaws.com/infrastructure.yaml \
    --parameters \
        ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        ParameterKey=DatabasePassword,ParameterValue=${DB_PASSWORD} \
        ParameterKey=OllamaModel,ParameterValue=llama2 \
    --capabilities CAPABILITY_IAM \
    --region ${REGION}

echo -e "${YELLOW}⏳ Waiting for stack creation to complete...${NC}"
aws cloudformation wait stack-create-complete \
    --stack-name ${STACK_NAME} \
    --region ${REGION}

# Get stack outputs
echo -e "${YELLOW}📋 Getting stack outputs${NC}"
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].Outputs')

# Extract values
DATABASE_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
OLLAMA_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="OllamaEndpoint") | .OutputValue')
REDIS_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="RedisEndpoint") | .OutputValue')
S3_BUCKET=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="S3Bucket") | .OutputValue')

echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
echo -e "${GREEN}📊 Stack Outputs:${NC}"
echo -e "${YELLOW}Database Endpoint: ${DATABASE_ENDPOINT}${NC}"
echo -e "${YELLOW}Ollama Endpoint: ${OLLAMA_ENDPOINT}${NC}"
echo -e "${YELLOW}Redis Endpoint: ${REDIS_ENDPOINT}${NC}"
echo -e "${YELLOW}S3 Bucket: ${S3_BUCKET}${NC}"

# Create environment configuration file
echo -e "${YELLOW}📝 Creating environment configuration${NC}"
cat > ../.env.production << EOF
# Production Environment Configuration
ENVIRONMENT=production
AWS_REGION=${REGION}

# Database Configuration
DB_NAME=recruitment_portal
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DATABASE_ENDPOINT}
DB_PORT=5432

# AWS Services
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
AWS_STORAGE_BUCKET_NAME=${S3_BUCKET}
AWS_S3_REGION_NAME=${REGION}

# AI Configuration
OLLAMA_HOST=http://${OLLAMA_ENDPOINT}:11434
OLLAMA_MODEL=llama2
OLLAMA_PROVIDER=aws
AI_PROVIDER=ollama

# Redis Configuration
REDIS_URL=redis://${REDIS_ENDPOINT}:6379/0

# DynamoDB Configuration
DYNAMODB_ENABLED=true
DB_PROVIDER=hybrid

# Django Settings
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,*.amazonaws.com

# Auto-merge settings
AUTO_MERGE_HOURS=24
EOF

echo -e "${GREEN}✅ Environment configuration created: .env.production${NC}"

# Test Ollama connection
echo -e "${YELLOW}🧪 Testing Ollama connection...${NC}"
sleep 30  # Wait for Ollama to start
if curl -s http://${OLLAMA_ENDPOINT}:11434/api/tags > /dev/null; then
    echo -e "${GREEN}✅ Ollama is running and accessible${NC}"
else
    echo -e "${RED}❌ Ollama is not accessible. Please check the EC2 instance.${NC}"
fi

# Create deployment summary
cat > deployment-summary.md << EOF
# Deployment Summary

## Infrastructure Details
- **Stack Name**: ${STACK_NAME}
- **Environment**: ${ENVIRONMENT}
- **Region**: ${REGION}

## Service Endpoints
- **Database**: ${DATABASE_ENDPOINT}
- **Ollama**: http://${OLLAMA_ENDPOINT}:11434
- **Redis**: ${REDIS_ENDPOINT}
- **S3 Bucket**: ${S3_BUCKET}

## Next Steps
1. Update your local .env file with the production settings
2. Run database migrations: \`python manage.py migrate\`
3. Create superuser: \`python manage.py createsuperuser\`
4. Start the application: \`python manage.py runserver\`

## Local Development Setup
To connect to AWS services locally:
1. Copy the .env.production file to your local .env
2. Install AWS CLI and configure credentials
3. Test the connection to AWS services
EOF

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}📄 Deployment summary saved to: deployment-summary.md${NC}"
echo -e "${YELLOW}🔧 Next steps:${NC}"
echo -e "1. Copy .env.production to your local .env file"
echo -e "2. Run: python manage.py migrate"
echo -e "3. Run: python manage.py createsuperuser"
echo -e "4. Start the application: python manage.py runserver" 