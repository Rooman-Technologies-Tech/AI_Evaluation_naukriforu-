#!/bin/bash

# Local Development Setup Script for Recruitment Portal
# This script sets up the local development environment with AWS services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Setting up Local Development Environment${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites verified${NC}"

# Start DynamoDB Local
echo -e "${YELLOW}📊 Starting DynamoDB Local...${NC}"
docker run -d \
    --name dynamodb-local \
    -p 8000:8000 \
    amazon/dynamodb-local \
    -jar DynamoDBLocal.jar -sharedDb

# Wait for DynamoDB to start
sleep 5

# Create DynamoDB tables locally
echo -e "${YELLOW}📋 Creating DynamoDB tables...${NC}"

# Create search indexes table
aws dynamodb create-table \
    --table-name development-search-indexes \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
        AttributeName=candidate_id,AttributeType=S \
        AttributeName=search_type,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --global-secondary-indexes \
        IndexName=CandidateSearchIndex,KeySchema=[{AttributeName=candidate_id,KeyType=HASH},{AttributeName=search_type,KeyType=RANGE}],Projection={ProjectionType=ALL} \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://localhost:8000

# Create analytics table
aws dynamodb create-table \
    --table-name development-analytics \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
        AttributeName=date,AttributeType=S \
        AttributeName=metric_type,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --global-secondary-indexes \
        IndexName=DateMetricIndex,KeySchema=[{AttributeName=date,KeyType=HASH},{AttributeName=metric_type,KeyType=RANGE}],Projection={ProjectionType=ALL} \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://localhost:8000

# Create cached results table
aws dynamodb create-table \
    --table-name development-cached-results \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://localhost:8000

echo -e "${GREEN}✅ DynamoDB tables created successfully${NC}"

# Start Redis
echo -e "${YELLOW}🔴 Starting Redis...${NC}"
docker run -d \
    --name redis-local \
    -p 6379:6379 \
    redis:7-alpine

echo -e "${GREEN}✅ Redis started successfully${NC}"

# Create local environment configuration
echo -e "${YELLOW}📝 Creating local environment configuration...${NC}"

cat > ../.env.local << EOF
# Local Development Environment Configuration
ENVIRONMENT=development
AWS_REGION=us-east-1

# Database Configuration (Local PostgreSQL)
DB_NAME=recruitment_portal
DB_USER=recruitment_user
DB_PASSWORD=recruitment123
DB_HOST=localhost
DB_PORT=5432

# AWS Services (Local)
AWS_ACCESS_KEY_ID=local
AWS_SECRET_ACCESS_KEY=local
AWS_STORAGE_BUCKET_NAME=local-resume-storage
AWS_S3_REGION_NAME=us-east-1

# AI Configuration (Local Ollama)
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama2
OLLAMA_PROVIDER=local
AI_PROVIDER=ollama

# Redis Configuration (Local)
REDIS_URL=redis://localhost:6379/0

# DynamoDB Configuration (Local)
DYNAMODB_ENABLED=true
DB_PROVIDER=hybrid
DYNAMODB_ENDPOINT_URL=http://localhost:8000

# Django Settings
SECRET_KEY=django-insecure-local-development-key-change-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Auto-merge settings
AUTO_MERGE_HOURS=24
EOF

echo -e "${GREEN}✅ Local environment configuration created: .env.local${NC}"

# Install AWS CLI local configuration
echo -e "${YELLOW}⚙️  Configuring AWS CLI for local development...${NC}"

# Create AWS CLI profile for local development
aws configure set aws_access_key_id local --profile local
aws configure set aws_secret_access_key local --profile local
aws configure set region us-east-1 --profile local
aws configure set output json --profile local

echo -e "${GREEN}✅ AWS CLI configured for local development${NC}"

# Create helper scripts
echo -e "${YELLOW}📜 Creating helper scripts...${NC}"

# Script to start all services
cat > start-services.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting all development services..."

# Start DynamoDB Local
docker start dynamodb-local 2>/dev/null || docker run -d --name dynamodb-local -p 8000:8000 amazon/dynamodb-local -jar DynamoDBLocal.jar -sharedDb

# Start Redis
docker start redis-local 2>/dev/null || docker run -d --name redis-local -p 6379:6379 redis:7-alpine

# Start PostgreSQL (if not running)
sudo systemctl start postgresql

# Start Ollama (if installed)
if command -v ollama &> /dev/null; then
    ollama serve &
fi

echo "✅ All services started!"
echo "📊 DynamoDB Local: http://localhost:8000"
echo "🔴 Redis: localhost:6379"
echo "🐘 PostgreSQL: localhost:5432"
echo "🤖 Ollama: http://localhost:11434"
EOF

# Script to stop all services
cat > stop-services.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping all development services..."

# Stop Docker containers
docker stop dynamodb-local 2>/dev/null || true
docker stop redis-local 2>/dev/null || true

# Stop Ollama
pkill -f ollama 2>/dev/null || true

echo "✅ All services stopped!"
EOF

# Make scripts executable
chmod +x start-services.sh stop-services.sh

echo -e "${GREEN}✅ Helper scripts created${NC}"

# Create development guide
cat > local-development-guide.md << 'EOF'
# Local Development Guide

## Services

### DynamoDB Local
- **URL**: http://localhost:8000
- **Status**: Running in Docker
- **Tables**: 
  - development-search-indexes
  - development-analytics
  - development-cached-results

### Redis
- **URL**: localhost:6379
- **Status**: Running in Docker
- **Purpose**: Caching and Celery

### PostgreSQL
- **URL**: localhost:5432
- **Database**: recruitment_portal
- **Status**: Local installation

### Ollama
- **URL**: http://localhost:11434
- **Status**: Local installation
- **Model**: llama2

## Environment Configuration

The local environment uses `.env.local` with the following configuration:
- **Database Provider**: Hybrid (PostgreSQL + DynamoDB)
- **AI Provider**: Local Ollama
- **Cache**: Local Redis
- **Storage**: Local file system

## Quick Start

1. **Start all services**:
   ```bash
   ./start-services.sh
   ```

2. **Activate virtual environment**:
   ```bash
   source match/bin/activate
   ```

3. **Set environment**:
   ```bash
   cp .env.local .env
   ```

4. **Run migrations**:
   ```bash
   python manage.py migrate
   ```

5. **Create superuser**:
   ```bash
   python manage.py createsuperuser
   ```

6. **Start Django server**:
   ```bash
   python manage.py runserver
   ```

7. **Start React frontend** (in another terminal):
   ```bash
   cd frontend
   npm start
   ```

## Testing AWS Services Locally

### DynamoDB
```bash
# List tables
aws dynamodb list-tables --endpoint-url http://localhost:8000

# Scan a table
aws dynamodb scan --table-name development-search-indexes --endpoint-url http://localhost:8000
```

### S3 (LocalStack - Optional)
If you want to test S3 locally, you can use LocalStack:
```bash
docker run -d --name localstack -p 4566:4566 localstack/localstack
```

## Troubleshooting

### DynamoDB Connection Issues
- Check if DynamoDB Local is running: `docker ps | grep dynamodb`
- Restart: `docker restart dynamodb-local`

### Redis Connection Issues
- Check if Redis is running: `docker ps | grep redis`
- Restart: `docker restart redis-local`

### PostgreSQL Connection Issues
- Check if PostgreSQL is running: `sudo systemctl status postgresql`
- Start: `sudo systemctl start postgresql`

### Ollama Connection Issues
- Check if Ollama is running: `curl http://localhost:11434/api/tags`
- Start: `ollama serve`
EOF

echo -e "${GREEN}✅ Local development guide created: local-development-guide.md${NC}"

echo -e "${GREEN}🎉 Local development environment setup completed!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "1. Copy .env.local to your project root as .env"
echo -e "2. Run: ./start-services.sh"
echo -e "3. Activate your virtual environment: source match/bin/activate"
echo -e "4. Run migrations: python manage.py migrate"
echo -e "5. Start the application: python manage.py runserver"
echo -e ""
echo -e "${GREEN}📚 Check local-development-guide.md for detailed instructions${NC}" 