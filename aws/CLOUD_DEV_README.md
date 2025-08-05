# Cloud Development Setup for Recruitment Portal

## 🎯 Overview

This setup provides a **cloud-based development environment** where developers only need to run their code locally while connecting to AWS services for database, AI, and storage. This approach ensures consistency across all developers and provides production-like testing.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Code    │    │   AWS RDS       │    │   AWS EC2       │
│   (Django)      │◄──►│   (PostgreSQL)  │    │   (Ollama)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Redis   │    │   AWS DynamoDB  │    │   AWS S3        │
│   (Caching)     │    │   (Search)      │    │   (Files)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Files Overview

### Setup Scripts
- **`cloud-dev-setup.sh`** - Deploys AWS infrastructure for development
- **`dev-start.sh`** - Developer-friendly start script with menu options
- **`quick-start.sh`** - Complete setup with all options

### Infrastructure
- **`dev-infrastructure.yaml`** - CloudFormation template for development services
- **`hybrid-infrastructure.yaml`** - Full production infrastructure

### Documentation
- **`SETUP_GUIDE.md`** - Comprehensive setup guide
- **`README.md`** - General AWS setup documentation

## 🚀 Quick Start for Developers

### Option 1: One-Time Setup (Team Lead)
```bash
cd aws
./cloud-dev-setup.sh us-east-1 "YourSecurePassword123!" llama2
```

### Option 2: Daily Development (Developers)
```bash
cd aws
./dev-start.sh
```

## 🎯 Benefits of Cloud Development

### ✅ **For Developers**
- **No local database setup** - AWS RDS handles everything
- **No local AI model** - AWS EC2 runs Ollama
- **Consistent environment** - Same services for all developers
- **Production-like testing** - Real AWS services
- **Easy onboarding** - Just clone and run

### ✅ **For Teams**
- **Shared development database** - All developers use same data
- **Consistent AI model** - Same Ollama instance for all
- **Cost effective** - Pay only for what you use
- **Easy scaling** - AWS handles infrastructure
- **No environment conflicts** - No "works on my machine" issues

### ✅ **For Management**
- **Reduced setup time** - Developers can start coding immediately
- **Lower maintenance** - AWS manages infrastructure
- **Better testing** - Production-like environment
- **Cost control** - Predictable monthly costs

## 💰 Cost Breakdown

### Monthly Development Costs
- **RDS PostgreSQL (t3.micro)**: ~$15-20/month
- **EC2 Ollama (t3.medium)**: ~$30-40/month
- **DynamoDB (pay-per-request)**: ~$5-10/month
- **S3 Storage**: ~$1-5/month
- **Total**: ~$50-75/month

### Cost Optimization Tips
1. **Stop EC2 when not in use** - Save ~70% of EC2 costs
2. **Use RDS reserved instances** - For long-term development
3. **Monitor DynamoDB usage** - Optimize queries
4. **Clean up S3 objects** - Regular cleanup

## 🔧 Configuration

### Environment Variables (.env.cloud-dev)
```env
# Database Configuration (AWS RDS)
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=5432
DB_NAME=recruitment_portal
DB_USER=postgres
DB_PASSWORD=YourSecurePassword123!

# AI Configuration (AWS EC2)
OLLAMA_HOST=http://your-ec2-ip:11434
OLLAMA_MODEL=llama2
OLLAMA_PROVIDER=aws

# AWS Services
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=your-s3-bucket

# DynamoDB Configuration
DYNAMODB_ENABLED=true
DB_PROVIDER=hybrid
```

## 🧪 Testing Connections

### Database Connection
```bash
# Test PostgreSQL connection
psql -U postgres -d recruitment_portal -h your-rds-endpoint.amazonaws.com -p 5432
```

### Ollama Connection
```bash
# Test Ollama API
curl http://your-ec2-ip:11434/api/tags
```

### DynamoDB Connection
```bash
# List tables
aws dynamodb list-tables --region us-east-1

# Test table access
aws dynamodb scan --table-name development-search-indexes --region us-east-1
```

## 🔒 Security

### Network Security
- **RDS**: Publicly accessible for development (not for production)
- **EC2**: Public IP with security group allowing 11434 and 22
- **DynamoDB**: AWS managed with IAM access

### Access Control
- **Database**: Username/password authentication
- **EC2**: SSH key pair for direct access
- **AWS Services**: IAM credentials

## 🚨 Troubleshooting

### Database Connection Issues
```bash
# Check if RDS is accessible
telnet your-rds-endpoint.amazonaws.com 5432

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

### Ollama Connection Issues
```bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids i-xxxxxxxxx

# SSH into EC2 to check Ollama
ssh -i ~/.ssh/development-recruitment-portal-key.pem ec2-user@your-ec2-ip
```

### DynamoDB Issues
```bash
# Check table status
aws dynamodb describe-table --table-name development-search-indexes --region us-east-1
```

## 📊 Monitoring

### CloudWatch Metrics
- **RDS**: Database connections, CPU, memory
- **EC2**: CPU, memory, network
- **DynamoDB**: Read/write capacity

### Application Logs
- **Django**: Local log files
- **AWS**: CloudWatch logs for EC2

## 🔄 Development Workflow

### Daily Development
1. **Start the application**:
   ```bash
   cd aws
   ./dev-start.sh
   ```

2. **Code locally** in your IDE
3. **Test with real data** in AWS
4. **Deploy to production** when ready

### Team Collaboration
1. **Shared database** - All developers use same RDS instance
2. **Shared AI model** - All developers use same Ollama instance
3. **Shared file storage** - All developers use same S3 bucket
4. **Consistent environment** - No setup differences

## 📚 Setup Instructions

### For Team Lead (One-time setup)
1. **Install AWS CLI** and configure credentials
2. **Run cloud setup**:
   ```bash
   cd aws
   ./cloud-dev-setup.sh us-east-1 "YourSecurePassword123!" llama2
   ```
3. **Share environment file** with team
4. **Monitor costs** and optimize

### For Developers (Daily use)
1. **Clone the repository**
2. **Copy environment file**:
   ```bash
   cp .env.cloud-dev .env
   ```
3. **Start development**:
   ```bash
   cd aws
   ./dev-start.sh
   ```
4. **Start coding**!

## 🎯 Success Indicators

Your cloud development setup is successful when:

✅ **Infrastructure**
- RDS PostgreSQL accessible from local machine
- EC2 Ollama responding to API calls
- DynamoDB tables created and accessible
- S3 bucket configured for file storage

✅ **Application**
- Django server starts without errors
- Database migrations run successfully
- AI search features work with Ollama
- File uploads work with S3

✅ **Development Experience**
- Developers can start coding immediately
- No local database setup required
- Consistent environment across team
- Production-like testing capabilities

## 📚 Additional Resources

- **`SETUP_GUIDE.md`** - Comprehensive setup guide
- **`README.md`** - General AWS setup documentation
- **AWS Documentation** - [AWS Docs](https://docs.aws.amazon.com/)
- **Django Documentation** - [Django Docs](https://docs.djangoproject.com/)
- **Ollama Documentation** - [Ollama Docs](https://ollama.ai/docs)

## 🤝 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Test individual service connections
4. Check AWS service status
5. Review security group configurations

---

**🎉 Your cloud development environment is ready for team collaboration!**

This setup provides the perfect balance between local development flexibility and cloud infrastructure benefits, making it ideal for teams working on the recruitment portal. 