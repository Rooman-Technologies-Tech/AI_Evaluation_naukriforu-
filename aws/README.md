# AWS Hybrid Setup for Recruitment Portal

## 🎯 Overview

This directory contains all the necessary files and scripts to set up the recruitment portal with a hybrid database approach using PostgreSQL and DynamoDB, with Ollama deployed on AWS EC2.

## 📁 Files Overview

### Infrastructure Files
- **`hybrid-infrastructure.yaml`** - CloudFormation template for AWS infrastructure
- **`deployment.yaml`** - Original deployment template (legacy)

### Scripts
- **`deploy.sh`** - AWS infrastructure deployment script
- **`local-setup.sh`** - Local development environment setup
- **`quick-start.sh`** - Complete setup script with menu options

### Documentation
- **`SETUP_GUIDE.md`** - Comprehensive setup guide
- **`README.md`** - This file

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
```bash
cd aws
./quick-start.sh
```

### Option 2: Manual Setup

#### Local Development
```bash
cd aws
./local-setup.sh
cp .env.local ../.env
cd ..
source match/bin/activate
python manage.py migrate
python manage.py runserver
```

#### AWS Production
```bash
cd aws
./deploy.sh development us-east-1 "YourSecurePassword123!"
cp .env.production ../.env
cd ..
source match/bin/activate
python manage.py migrate
python manage.py runserver
```

## 🏗️ Architecture

### Database Strategy
- **PostgreSQL (RDS)** - Primary database for relational data
- **DynamoDB** - Secondary database for search indexes and analytics
- **Redis (ElastiCache)** - Caching and Celery

### AI Services
- **Ollama on EC2** - AI model hosting
- **AWS Bedrock** - Alternative AI provider

### Storage
- **S3** - Resume file storage
- **Local File System** - Development storage

## 🔧 Configuration

### Environment Variables
The setup creates two environment configurations:

1. **`.env.local`** - Local development with Docker services
2. **`.env.production`** - AWS production environment

### Key Configuration Options
- `DB_PROVIDER=hybrid` - Use both PostgreSQL and DynamoDB
- `DYNAMODB_ENABLED=true` - Enable DynamoDB functionality
- `OLLAMA_PROVIDER=local|aws` - Choose AI provider
- `AI_PROVIDER=ollama|bedrock` - Choose AI service

## 🧪 Testing

### Local Services
```bash
# DynamoDB Local
aws dynamodb list-tables --endpoint-url http://localhost:8000

# Redis
redis-cli ping

# PostgreSQL
psql -U recruitment_user -d recruitment_portal -h localhost

# Ollama
curl http://localhost:11434/api/tags
```

### AWS Services
```bash
# RDS PostgreSQL
psql -U postgres -d recruitment_portal -h your-rds-endpoint.amazonaws.com

# DynamoDB
aws dynamodb list-tables --region us-east-1

# Ollama on EC2
curl http://your-ec2-endpoint:11434/api/tags
```

## 📊 Monitoring

### CloudWatch Metrics
- RDS: Database connections, CPU, memory
- DynamoDB: Read/write capacity, throttling
- EC2: CPU, memory, network
- ElastiCache: Memory, connections

### Application Metrics
- Search performance and response times
- AI model inference times
- Database query performance

## 🔒 Security

### AWS Security
- IAM roles with least privilege access
- Security groups restricting network access
- Encryption at rest and in transit
- VPC with private subnets

### Application Security
- Environment variables for secrets
- HTTPS in production
- Input validation
- Authentication and authorization

## 📈 Scaling

### Horizontal Scaling
- Multiple EC2 instances for application
- RDS read replicas
- ElastiCache clusters
- Multiple Ollama instances

### Vertical Scaling
- Upgrade EC2 instance types
- Upgrade RDS instance classes
- Increase DynamoDB capacity units

## 🚨 Troubleshooting

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

## 📚 Documentation

- **`SETUP_GUIDE.md`** - Comprehensive setup guide
- **AWS Documentation** - [AWS Docs](https://docs.aws.amazon.com/)
- **Django Documentation** - [Django Docs](https://docs.djangoproject.com/)
- **DynamoDB Documentation** - [DynamoDB Docs](https://docs.aws.amazon.com/dynamodb/)
- **Ollama Documentation** - [Ollama Docs](https://ollama.ai/docs)

## 🤝 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Test individual services
4. Check AWS service status
5. Review security group configurations

## 🎉 Success Indicators

Your setup is successful when:

✅ **Local Development**
- DynamoDB Local running on port 8000
- Redis running on port 6379
- PostgreSQL running on port 5432
- Ollama running on port 11434
- Django server accessible at http://localhost:8000
- React frontend accessible at http://localhost:3000

✅ **AWS Production**
- CloudFormation stack deployed successfully
- RDS PostgreSQL accessible
- DynamoDB tables created
- EC2 instance running Ollama
- S3 bucket configured
- ElastiCache Redis accessible

✅ **Application Features**
- User authentication working
- Candidate search functional
- Resume upload working
- AI-powered search operational
- Analytics data being collected

---

**🎯 Your hybrid PostgreSQL + DynamoDB recruitment portal with Ollama on AWS is ready!** 