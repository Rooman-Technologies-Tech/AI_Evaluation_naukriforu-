# Hybrid PostgreSQL + DynamoDB Setup Guide

## 🎯 Overview

This guide will help you set up the recruitment portal with a hybrid database approach:
- **PostgreSQL (RDS)** - Primary database for relational data
- **DynamoDB** - Secondary database for search indexes and analytics
- **Ollama on AWS EC2** - AI model deployment
- **Local Development** - Full local environment with AWS services

## 📋 Prerequisites

### Required Software
- **Python 3.12+**
- **Node.js 18+**
- **Docker** - For local DynamoDB and Redis
- **AWS CLI v2** - For AWS deployment
- **PostgreSQL** - Local development
- **Redis** - Local development
- **Ollama** - Local AI development

### AWS Account Setup
1. **Create AWS Account** - [Sign up here](https://aws.amazon.com/)
2. **Install AWS CLI** - [Installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **Configure AWS Credentials**:
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter your default region (e.g., us-east-1)
   # Enter your output format (json)
   ```

## 🚀 Quick Start

### Option 1: Local Development Setup

1. **Run the local setup script**:
   ```bash
   cd aws
   ./local-setup.sh
   ```

2. **Copy environment configuration**:
   ```bash
   cp .env.local .env
   ```

3. **Activate virtual environment**:
   ```bash
   source match/bin/activate
   ```

4. **Run database migrations**:
   ```bash
   python manage.py migrate
   ```

5. **Create superuser**:
   ```bash
   python manage.py createsuperuser
   ```

6. **Start the application**:
   ```bash
   python manage.py runserver
   ```

### Option 2: AWS Production Deployment

1. **Deploy AWS infrastructure**:
   ```bash
   cd aws
   ./deploy.sh development us-east-1 "YourSecurePassword123!"
   ```

2. **Copy production environment**:
   ```bash
   cp .env.production .env
   ```

3. **Run migrations and start application**:
   ```bash
   source match/bin/activate
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py runserver
   ```

## 🏗️ Architecture

### Database Strategy

#### PostgreSQL (Primary Database)
- **Candidate Profiles** - Relational data with complex relationships
- **Resume Metadata** - File references and processing status
- **Job Descriptions** - Structured job data
- **User Management** - Django auth and permissions
- **Workflow Data** - Approval processes and updates

#### DynamoDB (Secondary Database)
- **Search Indexes** - Vector embeddings for AI search
- **Analytics Data** - Search history and metrics
- **Cached Results** - AI search results and recommendations
- **Session Data** - User sessions and preferences

### AWS Services

#### Infrastructure Components
- **RDS PostgreSQL** - Managed PostgreSQL database
- **DynamoDB** - NoSQL database for search and analytics
- **S3** - File storage for resumes
- **EC2** - Ollama model hosting
- **ElastiCache Redis** - Caching and Celery
- **Application Load Balancer** - Traffic distribution

#### Ollama Deployment
- **EC2 Instance** - t3.medium with Amazon Linux 2023
- **Docker Container** - Containerized Ollama service
- **Auto Scaling** - Scale based on demand
- **CloudWatch** - Monitoring and logging

## 🔧 Configuration

### Environment Variables

#### Local Development (.env.local)
```env
ENVIRONMENT=development
AWS_REGION=us-east-1

# Database Configuration
DB_NAME=recruitment_portal
DB_USER=recruitment_user
DB_PASSWORD=recruitment123
DB_HOST=localhost
DB_PORT=5432

# AWS Services (Local)
AWS_ACCESS_KEY_ID=local
AWS_SECRET_ACCESS_KEY=local
AWS_STORAGE_BUCKET_NAME=local-resume-storage

# AI Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama2
OLLAMA_PROVIDER=local
AI_PROVIDER=ollama

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# DynamoDB Configuration
DYNAMODB_ENABLED=true
DB_PROVIDER=hybrid
DYNAMODB_ENDPOINT_URL=http://localhost:8000

# Django Settings
SECRET_KEY=django-insecure-local-development-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
```

#### Production (.env.production)
```env
ENVIRONMENT=production
AWS_REGION=us-east-1

# Database Configuration
DB_NAME=recruitment_portal
DB_USER=postgres
DB_PASSWORD=YourSecurePassword123!
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=5432

# AWS Services
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=your-s3-bucket

# AI Configuration
OLLAMA_HOST=http://your-ec2-endpoint:11434
OLLAMA_MODEL=llama2
OLLAMA_PROVIDER=aws
AI_PROVIDER=ollama

# Redis Configuration
REDIS_URL=redis://your-elasticache-endpoint:6379/0

# DynamoDB Configuration
DYNAMODB_ENABLED=true
DB_PROVIDER=hybrid

# Django Settings
SECRET_KEY=your-production-secret-key
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,*.amazonaws.com
```

## 🧪 Testing

### Local Services

#### DynamoDB Local
```bash
# List tables
aws dynamodb list-tables --endpoint-url http://localhost:8000

# Scan a table
aws dynamodb scan --table-name development-search-indexes --endpoint-url http://localhost:8000
```

#### Redis
```bash
# Test Redis connection
redis-cli ping
# Should return: PONG
```

#### PostgreSQL
```bash
# Test database connection
psql -U recruitment_user -d recruitment_portal -h localhost
```

#### Ollama
```bash
# Test Ollama connection
curl http://localhost:11434/api/tags
# Should return available models
```

### AWS Services

#### RDS PostgreSQL
```bash
# Connect to RDS (replace with your endpoint)
psql -U postgres -d recruitment_portal -h your-rds-endpoint.amazonaws.com
```

#### DynamoDB
```bash
# List tables
aws dynamodb list-tables --region us-east-1

# Scan a table
aws dynamodb scan --table-name development-search-indexes --region us-east-1
```

#### Ollama on EC2
```bash
# Test Ollama on EC2 (replace with your endpoint)
curl http://your-ec2-endpoint:11434/api/tags
```

## 🔍 Troubleshooting

### Common Issues

#### Database Connection Errors
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check RDS connectivity
telnet your-rds-endpoint.amazonaws.com 5432
```

#### DynamoDB Issues
```bash
# Check DynamoDB Local
docker ps | grep dynamodb

# Restart DynamoDB Local
docker restart dynamodb-local
```

#### Redis Issues
```bash
# Check Redis status
docker ps | grep redis

# Restart Redis
docker restart redis-local
```

#### Ollama Issues
```bash
# Check Ollama status
curl http://localhost:11434/api/tags

# Start Ollama
ollama serve
```

#### AWS CLI Issues
```bash
# Check AWS credentials
aws sts get-caller-identity

# Configure AWS credentials
aws configure
```

### Performance Optimization

#### Database Optimization
- **PostgreSQL**: Enable connection pooling with PgBouncer
- **DynamoDB**: Use appropriate read/write capacity units
- **Redis**: Configure memory limits and eviction policies

#### AI Model Optimization
- **Ollama**: Use appropriate EC2 instance types
- **Caching**: Implement result caching in DynamoDB
- **Load Balancing**: Use Application Load Balancer for Ollama

## 📊 Monitoring

### CloudWatch Metrics
- **RDS**: Database connections, CPU, memory
- **DynamoDB**: Read/write capacity, throttling
- **EC2**: CPU, memory, network
- **ElastiCache**: Memory, connections

### Application Metrics
- **Search Performance**: Response times, hit rates
- **AI Model**: Inference times, accuracy
- **Database**: Query performance, connection pools

## 🔒 Security

### AWS Security Best Practices
- **IAM Roles**: Use least privilege access
- **Security Groups**: Restrict network access
- **Encryption**: Enable encryption at rest and in transit
- **VPC**: Use private subnets for databases

### Application Security
- **Environment Variables**: Never commit secrets to code
- **HTTPS**: Use SSL/TLS in production
- **Authentication**: Implement proper user authentication
- **Input Validation**: Validate all user inputs

## 📈 Scaling

### Horizontal Scaling
- **Application**: Use multiple EC2 instances
- **Database**: Use RDS read replicas
- **Cache**: Use ElastiCache clusters
- **AI**: Use multiple Ollama instances

### Vertical Scaling
- **EC2**: Upgrade instance types
- **RDS**: Upgrade instance classes
- **DynamoDB**: Increase capacity units

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] AWS CLI installed and configured
- [ ] Docker installed (for local development)
- [ ] Virtual environment activated
- [ ] Environment variables configured
- [ ] Database migrations ready

### Local Development
- [ ] DynamoDB Local running
- [ ] Redis running
- [ ] PostgreSQL running
- [ ] Ollama running
- [ ] Django migrations applied
- [ ] Superuser created
- [ ] Frontend dependencies installed

### AWS Production
- [ ] CloudFormation stack deployed
- [ ] Environment variables updated
- [ ] Database migrations applied
- [ ] SSL certificates configured
- [ ] Monitoring and logging enabled
- [ ] Backup strategy implemented

## 📚 Additional Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Django Documentation](https://docs.djangoproject.com/)
- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [Ollama Documentation](https://ollama.ai/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🤝 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the logs in CloudWatch
3. Test individual services
4. Check AWS service status
5. Review security group configurations

---

**🎉 Your hybrid PostgreSQL + DynamoDB recruitment portal is ready!** 