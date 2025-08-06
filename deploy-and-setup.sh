#!/bin/bash

# Recruitment Portal - Deploy CFT and Setup Environment
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="recruitment-portal-dev"
REGION="ap-south-1"
ENVIRONMENT="development"
CFT_FILE="aws/dev-infrastructure.yaml"

echo -e "${BLUE}🚀 Starting Recruitment Portal Deployment and Setup${NC}"
echo "=================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if CFT file exists
if [ ! -f "$CFT_FILE" ]; then
    echo -e "${RED}❌ CloudFormation template not found at $CFT_FILE${NC}"
    exit 1
fi

# Prompt for database password if not set
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${YELLOW}🔐 Enter database password for RDS:${NC}"
    read -s DB_PASSWORD
    if [ -z "$DB_PASSWORD" ]; then
        echo -e "${RED}❌ Database password is required${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}📋 Deployment Configuration:${NC}"
echo "  Stack Name: $STACK_NAME"
echo "  Region: $REGION"
echo "  Environment: $ENVIRONMENT"
echo "  Template: $CFT_FILE"
echo ""

# Check if stack exists and handle ROLLBACK_COMPLETE state
echo -e "${YELLOW}🔍 Checking existing stack status...${NC}"
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" = "ROLLBACK_COMPLETE" ]; then
    echo -e "${YELLOW}⚠️  Stack is in ROLLBACK_COMPLETE state. Deleting it first...${NC}"
    aws cloudformation delete-stack \
        --stack-name $STACK_NAME \
        --region $REGION
    
    echo -e "${YELLOW}⏳ Waiting for stack deletion to complete...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    echo -e "${GREEN}✅ Stack deleted successfully${NC}"
elif [ "$STACK_STATUS" != "DOES_NOT_EXIST" ]; then
    echo -e "${BLUE}ℹ️  Existing stack status: $STACK_STATUS${NC}"
fi

# Deploy CloudFormation stack
echo -e "${YELLOW}🔄 Deploying CloudFormation stack...${NC}"
aws cloudformation deploy \
    --template-file $CFT_FILE \
    --stack-name $STACK_NAME \
    --region $REGION \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
        DatabasePassword=$DB_PASSWORD \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CloudFormation deployment completed successfully${NC}"
else
    echo -e "${RED}❌ CloudFormation deployment failed${NC}"
    exit 1
fi

# Wait for stack to be ready
echo -e "${YELLOW}⏳ Waiting for stack to be ready...${NC}"
# Check current stack status instead of using wait command that may not exist
CURRENT_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [[ "$CURRENT_STATUS" =~ ^(CREATE_COMPLETE|UPDATE_COMPLETE)$ ]]; then
    echo -e "${GREEN}✅ Stack is ready (Status: $CURRENT_STATUS)${NC}"
else
    echo -e "${YELLOW}⏳ Waiting for stack to complete...${NC}"
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION 2>/dev/null || \
    aws cloudformation wait stack-update-complete \
        --stack-name $STACK_NAME \
        --region $REGION 2>/dev/null || \
    echo -e "${YELLOW}⚠️  Could not wait for stack completion, but continuing...${NC}"
fi

# Fetch stack outputs
echo -e "${YELLOW}📝 Fetching stack outputs...${NC}"
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output json)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to fetch stack outputs${NC}"
    exit 1
fi

# Parse outputs and create environment file
echo -e "${YELLOW}🔧 Creating environment configuration...${NC}"

# Extract values from outputs
DATABASE_ENDPOINT=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
DATABASE_PORT=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="DatabasePort") | .OutputValue')
DYNAMODB_TABLES=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="DynamoDBTables") | .OutputValue')
S3_BUCKET=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="S3Bucket") | .OutputValue')
OLLAMA_ENDPOINT=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="OllamaEndpoint") | .OutputValue')
OLLAMA_PUBLIC_IP=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="OllamaPublicIP") | .OutputValue')

# Create backend environment file
cat > recruitment_portal/.env << EOF
# Database Configuration
DATABASE_HOST=$DATABASE_ENDPOINT
DATABASE_PORT=$DATABASE_PORT
DATABASE_NAME=recruitment_portal
DATABASE_USER=postgres
DATABASE_PASSWORD=$DB_PASSWORD

# AWS Configuration
AWS_REGION=$REGION
AWS_S3_BUCKET=$S3_BUCKET
DYNAMODB_TABLES=$DYNAMODB_TABLES

# AI/Ollama Configuration
OLLAMA_ENDPOINT=$OLLAMA_ENDPOINT
OLLAMA_PUBLIC_IP=$OLLAMA_PUBLIC_IP

# Django Configuration
DEBUG=True
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

# Environment
ENVIRONMENT=$ENVIRONMENT
EOF

# Create frontend environment file
cat > frontend/.env << EOF
# API Configuration
REACT_APP_API_URL=http://localhost:8000
REACT_APP_ENVIRONMENT=$ENVIRONMENT

# AWS Configuration (for client-side if needed)
REACT_APP_AWS_REGION=$REGION
REACT_APP_S3_BUCKET=$S3_BUCKET
REACT_APP_OLLAMA_ENDPOINT=$OLLAMA_ENDPOINT
EOF

echo -e "${GREEN}✅ Environment files created successfully${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "  Database Endpoint: $DATABASE_ENDPOINT:$DATABASE_PORT"
echo "  S3 Bucket: $S3_BUCKET"
echo "  DynamoDB Tables: $DYNAMODB_TABLES"
echo "  Ollama Endpoint: $OLLAMA_ENDPOINT"
echo "  Ollama Public IP: $OLLAMA_PUBLIC_IP"
echo ""

# Save outputs to JSON file for reference
echo "$OUTPUTS" > aws-outputs.json
echo -e "${GREEN}✅ Stack outputs saved to aws-outputs.json${NC}"

echo -e "${GREEN}🎉 Deployment and setup completed successfully!${NC}"
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Run ./start-applications.sh to start both frontend and backend"
echo "  2. Check the .env files in both directories for configuration"
echo "  3. Access the application at http://localhost:3000"
echo ""