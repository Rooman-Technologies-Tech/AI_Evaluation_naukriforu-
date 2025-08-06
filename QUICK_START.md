# Recruitment Portal - Quick Start Guide

## Overview
This guide walks you through deploying the AWS infrastructure and running both the frontend and backend applications.

## Prerequisites
- AWS CLI configured with appropriate permissions
- Node.js and npm installed
- Python 3.x installed
- jq (for JSON parsing in scripts)

## Step-by-Step Instructions

### 1. Deploy AWS Infrastructure and Setup Environment

```bash
# Set database password as environment variable (recommended)
export DB_PASSWORD="your-secure-password-here"

# Run the deployment script
./deploy-and-setup.sh
```

This script will:
- Deploy the CloudFormation template (`aws/dev-infrastructure.yaml`)
- Create RDS PostgreSQL database
- Set up DynamoDB tables
- Launch Ollama EC2 instance
- Create S3 bucket for resume storage
- Fetch all API endpoints and configuration
- Generate `.env` files for both frontend and backend

### 2. Start Both Applications

```bash
# Start frontend and backend together
./start-applications.sh
```

This script will:
- Check prerequisites and dependencies
- Install missing dependencies
- Run Django migrations
- Start Django backend on port 8000
- Start React frontend on port 3000
- Monitor both processes
- Provide logs and health checks

### 3. Access the Applications

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Admin Panel**: http://localhost:8000/admin

### 4. Stop Applications

Press `Ctrl+C` in the terminal running `start-applications.sh` to gracefully stop both services.

## Configuration Files

After running `deploy-and-setup.sh`, the following configuration files are created:

### Backend Configuration (`recruitment_portal/.env`)
```bash
DATABASE_HOST=your-rds-endpoint
DATABASE_PORT=5432
DATABASE_NAME=recruitment_portal
DATABASE_USER=postgres
DATABASE_PASSWORD=your-password
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-s3-bucket
DYNAMODB_TABLES=table1,table2
OLLAMA_ENDPOINT=http://your-ollama-instance:11434
```

### Frontend Configuration (`frontend/.env`)
```bash
REACT_APP_API_URL=http://localhost:8000
REACT_APP_ENVIRONMENT=development
REACT_APP_AWS_REGION=us-east-1
REACT_APP_S3_BUCKET=your-s3-bucket
REACT_APP_OLLAMA_ENDPOINT=http://your-ollama-instance:11434
```

## CloudFormation Outputs

The deployment script fetches these key outputs from AWS:
- **DatabaseEndpoint**: RDS PostgreSQL endpoint
- **DatabasePort**: Database port (typically 5432)
- **DynamoDBTables**: Comma-separated list of DynamoDB table names
- **S3Bucket**: S3 bucket name for resume storage
- **OllamaEndpoint**: Ollama API endpoint URL
- **OllamaPublicIP**: Ollama instance public IP

## Troubleshooting

### Port Already in Use
If you get port conflicts:
```bash
# Kill processes on port 8000 (backend)
sudo lsof -ti:8000 | xargs kill -9

# Kill processes on port 3000 (frontend)
sudo lsof -ti:3000 | xargs kill -9
```

### Check Logs
View application logs:
```bash
# Backend logs
tail -f backend.log

# Frontend logs
tail -f frontend.log
```

### AWS CLI Issues
Ensure AWS CLI is configured:
```bash
aws configure
aws sts get-caller-identity
```

### Database Connection Issues
Check if the RDS instance is running:
```bash
aws rds describe-db-instances --region us-east-1
```

## Manual Commands (Alternative)

If you prefer to run things manually:

### Deploy Infrastructure Only
```bash
cd aws
./deploy-dev.sh
```

### Run Backend Only
```bash
cd recruitment_portal
source venv/bin/activate
python manage.py runserver 8000
```

### Run Frontend Only
```bash
cd frontend
npm start
```

## File Structure

```
recruitment_portal/
├── deploy-and-setup.sh       # Main deployment script
├── start-applications.sh     # Application startup script
├── aws/
│   └── dev-infrastructure.yaml  # CloudFormation template
├── frontend/
│   ├── public/
│   │   ├── index.html         # Main HTML template
│   │   └── manifest.json      # PWA manifest
│   ├── src/
│   │   ├── index.js          # React entry point
│   │   └── App.js            # Main React component
│   └── .env                  # Frontend environment (generated)
└── recruitment_portal/
    ├── manage.py             # Django management script
    ├── .env                  # Backend environment (generated)
    └── ...
```

## Environment Variables

### Required for Deployment
- `DB_PASSWORD`: PostgreSQL database password

### Optional Overrides
- `REGION`: AWS region (default: us-east-1)
- `STACK_NAME`: CloudFormation stack name (default: recruitment-portal-dev)
- `ENVIRONMENT`: Environment name (default: development)

## Support

If you encounter issues:
1. Check the logs (`backend.log`, `frontend.log`)
2. Verify AWS credentials and permissions
3. Ensure all prerequisites are installed
4. Check port availability
5. Verify CloudFormation stack deployment status