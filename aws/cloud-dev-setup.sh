#!/bin/bash

# Cloud Development Setup Script for Recruitment Portal
# This script sets up AWS services for local development:
# - RDS PostgreSQL (managed database)
# - Ollama on EC2 (AI model)
# - DynamoDB (for search indexes)
# - S3 (for file storage)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}☁️  Cloud Development Setup for Recruitment Portal${NC}"
echo -e "${YELLOW}================================================${NC}"

# Configuration
STACK_NAME="recruitment-portal-dev"
ENVIRONMENT="development"
REGION=${1:-us-east-1}
DB_PASSWORD=${2:-"DevPassword123!"}
OLLAMA_MODEL=${3:-llama2}

echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}Region: ${REGION}${NC}"
echo -e "${YELLOW}Ollama Model: ${OLLAMA_MODEL}${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials are not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites verified${NC}"
}

# Create simplified CloudFormation template
create_dev_template() {
    echo -e "${YELLOW}📝 Creating development infrastructure template...${NC}"
    
    cat > dev-infrastructure.yaml << EOF
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Recruitment Portal Development Infrastructure - RDS + Ollama'

Parameters:
  Environment:
    Type: String
    Default: development
  
  DatabasePassword:
    Type: String
    NoEcho: true
    Description: Password for RDS database
  
  OllamaModel:
    Type: String
    Default: llama2
    Description: Ollama model to deploy

Resources:
  # VPC
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-dev-vpc'

  # Public Subnet
  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-public-subnet'

  # Private Subnet
  PrivateSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-private-subnet'

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-internet-gateway'

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  # NAT Gateway
  ElasticIP:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-nat-eip'

  NATGateway:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt ElasticIP.AllocationId
      SubnetId: !Ref PublicSubnet
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-nat-gateway'

  # Route Tables
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-public-route-table'

  PublicRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnetRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet
      RouteTableId: !Ref PublicRouteTable

  PrivateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-private-route-table'

  PrivateRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway

  PrivateSubnetRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet
      RouteTableId: !Ref PrivateRouteTable

  # Security Groups
  DatabaseSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for RDS PostgreSQL
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          CidrIp: 0.0.0.0/0  # Allow from anywhere for development
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-database-sg'

  OllamaSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Ollama EC2 instance
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 11434
          ToPort: 11434
          CidrIp: 0.0.0.0/0  # Allow from anywhere for development
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0  # SSH access for development
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-ollama-sg'

  # RDS PostgreSQL
  DatabaseSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for RDS PostgreSQL
      SubnetIds:
        - !Ref PrivateSubnet
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-database-subnet-group'

  DatabaseInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: !Sub '\${Environment}-recruitment-portal-db'
      DBInstanceClass: db.t3.micro
      Engine: postgres
      EngineVersion: '15.4'
      AllocatedStorage: 20
      StorageType: gp2
      MasterUsername: postgres
      MasterUserPassword: !Ref DatabasePassword
      DBName: recruitment_portal
      VPCSecurityGroups:
        - !Ref DatabaseSecurityGroup
      DBSubnetGroupName: !Ref DatabaseSubnetGroup
      BackupRetentionPeriod: 7
      MultiAZ: false
      PubliclyAccessible: true  # For development access
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-recruitment-portal-db'

  # DynamoDB Tables
  SearchIndexTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub '\${Environment}-search-indexes'
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
        - AttributeName: candidate_id
          AttributeType: S
        - AttributeName: search_type
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      GlobalSecondaryIndexes:
        - IndexName: CandidateSearchIndex
          KeySchema:
            - AttributeName: candidate_id
              KeyType: HASH
            - AttributeName: search_type
              KeyType: RANGE
          Projection:
            ProjectionType: ALL
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-search-indexes'

  AnalyticsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub '\${Environment}-analytics'
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
        - AttributeName: date
          AttributeType: S
        - AttributeName: metric_type
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      GlobalSecondaryIndexes:
        - IndexName: DateMetricIndex
          KeySchema:
            - AttributeName: date
              KeyType: HASH
            - AttributeName: metric_type
              KeyType: RANGE
          Projection:
            ProjectionType: ALL
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-analytics'

  # S3 Bucket for Resume Storage
  ResumeStorageBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '\${Environment}-recruitment-portal-resumes'
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-resume-storage'

  # EC2 Instance for Ollama
  OllamaInstance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t3.medium
      ImageId: ami-0c02fb55956c7d316  # Amazon Linux 2023
      KeyName: !Ref KeyPairName
      SecurityGroupIds:
        - !Ref OllamaSecurityGroup
      SubnetId: !Ref PublicSubnet
      IamInstanceProfile: !Ref OllamaInstanceProfile
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          yum install -y docker
          systemctl start docker
          systemctl enable docker
          
          # Install Ollama
          curl -fsSL https://ollama.ai/install.sh | sh
          
          # Pull the specified model
          ollama pull \${OllamaModel}
          
          # Start Ollama service
          systemctl enable ollama
          systemctl start ollama
          
          # Create Docker container for Ollama
          docker run -d \\
            --name ollama \\
            -p 11434:11434 \\
            -v ollama:/root/.ollama \\
            ollama/ollama
      Tags:
        - Key: Name
          Value: !Sub '\${Environment}-ollama-instance'

  # IAM Role for Ollama Instance
  OllamaInstanceRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub '\${Environment}-ollama-instance-role'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

  OllamaInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      InstanceProfileName: !Sub '\${Environment}-ollama-instance-profile'
      Roles:
        - !Ref OllamaInstanceRole

  # Key Pair for EC2
  KeyPairName:
    Type: AWS::EC2::KeyPair
    Properties:
      KeyName: !Sub '\${Environment}-recruitment-portal-key'

Outputs:
  VpcId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub '\${Environment}-vpc-id'

  DatabaseEndpoint:
    Description: RDS PostgreSQL endpoint
    Value: !GetAtt DatabaseInstance.Endpoint.Address
    Export:
      Name: !Sub '\${Environment}-database-endpoint'

  DatabasePort:
    Description: RDS PostgreSQL port
    Value: !GetAtt DatabaseInstance.Endpoint.Port
    Export:
      Name: !Sub '\${Environment}-database-port'

  DynamoDBTables:
    Description: DynamoDB table names
    Value: !Sub '\${SearchIndexTable.TableName},\${AnalyticsTable.TableName}'
    Export:
      Name: !Sub '\${Environment}-dynamodb-tables'

  S3Bucket:
    Description: S3 bucket for resume storage
    Value: !Ref ResumeStorageBucket
    Export:
      Name: !Sub '\${Environment}-s3-bucket'

  OllamaEndpoint:
    Description: Ollama EC2 instance endpoint
    Value: !GetAtt OllamaInstance.PublicDnsName
    Export:
      Name: !Sub '\${Environment}-ollama-endpoint'

  OllamaPublicIP:
    Description: Ollama EC2 instance public IP
    Value: !GetAtt OllamaInstance.PublicIp
    Export:
      Name: !Sub '\${Environment}-ollama-public-ip'
EOF

    echo -e "${GREEN}✅ Development infrastructure template created${NC}"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}🏗️  Deploying development infrastructure...${NC}"
    
    # Create S3 bucket for CloudFormation templates
    BUCKET_NAME="recruitment-portal-dev-templates-$(date +%s)"
    echo -e "${YELLOW}📦 Creating S3 bucket for templates: ${BUCKET_NAME}${NC}"
    aws s3 mb s3://${BUCKET_NAME} --region ${REGION}
    
    # Upload CloudFormation template
    echo -e "${YELLOW}📤 Uploading CloudFormation template${NC}"
    aws s3 cp dev-infrastructure.yaml s3://${BUCKET_NAME}/dev-infrastructure.yaml
    
    # Deploy CloudFormation stack
    echo -e "${YELLOW}🚀 Deploying CloudFormation stack${NC}"
    aws cloudformation create-stack \
        --stack-name ${STACK_NAME} \
        --template-url https://${BUCKET_NAME}.s3.amazonaws.com/dev-infrastructure.yaml \
        --parameters \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
            ParameterKey=DatabasePassword,ParameterValue=${DB_PASSWORD} \
            ParameterKey=OllamaModel,ParameterValue=${OLLAMA_MODEL} \
        --capabilities CAPABILITY_NAMED_IAM \
        --region ${REGION}
    
    echo -e "${YELLOW}⏳ Waiting for stack creation to complete...${NC}"
    aws cloudformation wait stack-create-complete \
        --stack-name ${STACK_NAME} \
        --region ${REGION}
    
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
}

# Get stack outputs
get_stack_outputs() {
    echo -e "${YELLOW}📋 Getting stack outputs...${NC}"
    
    STACK_OUTPUTS=$(aws cloudformation describe-stacks \
        --stack-name ${STACK_NAME} \
        --region ${REGION} \
        --query 'Stacks[0].Outputs')
    
    # Extract values
    DATABASE_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
    DATABASE_PORT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="DatabasePort") | .OutputValue')
    OLLAMA_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="OllamaEndpoint") | .OutputValue')
    OLLAMA_PUBLIC_IP=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="OllamaPublicIP") | .OutputValue')
    S3_BUCKET=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="S3Bucket") | .OutputValue')
    
    echo -e "${GREEN}📊 Stack Outputs:${NC}"
    echo -e "${YELLOW}Database Endpoint: ${DATABASE_ENDPOINT}${NC}"
    echo -e "${YELLOW}Database Port: ${DATABASE_PORT}${NC}"
    echo -e "${YELLOW}Ollama Endpoint: ${OLLAMA_ENDPOINT}${NC}"
    echo -e "${YELLOW}Ollama Public IP: ${OLLAMA_PUBLIC_IP}${NC}"
    echo -e "${YELLOW}S3 Bucket: ${S3_BUCKET}${NC}"
}

# Create development environment configuration
create_dev_config() {
    echo -e "${YELLOW}📝 Creating development environment configuration...${NC}"
    
    cat > ../.env.cloud-dev << EOF
# Cloud Development Environment Configuration
ENVIRONMENT=development
AWS_REGION=${REGION}

# Database Configuration (AWS RDS)
DB_NAME=recruitment_portal
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DATABASE_ENDPOINT}
DB_PORT=${DATABASE_PORT}

# AWS Services
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
AWS_STORAGE_BUCKET_NAME=${S3_BUCKET}
AWS_S3_REGION_NAME=${REGION}

# AI Configuration (AWS Ollama)
OLLAMA_HOST=http://${OLLAMA_PUBLIC_IP}:11434
OLLAMA_MODEL=${OLLAMA_MODEL}
OLLAMA_PROVIDER=aws
AI_PROVIDER=ollama

# Redis Configuration (Local for development)
REDIS_URL=redis://localhost:6379/0

# DynamoDB Configuration (AWS)
DYNAMODB_ENABLED=true
DB_PROVIDER=hybrid

# Django Settings
SECRET_KEY=django-insecure-cloud-development-key-change-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,${OLLAMA_PUBLIC_IP}

# Auto-merge settings
AUTO_MERGE_HOURS=24
EOF

    echo -e "${GREEN}✅ Development environment configuration created: .env.cloud-dev${NC}"
}

# Test connections
test_connections() {
    echo -e "${YELLOW}🧪 Testing connections...${NC}"
    
    # Test database connection
    echo -e "${YELLOW}📊 Testing database connection...${NC}"
    if nc -z ${DATABASE_ENDPOINT} ${DATABASE_PORT} 2>/dev/null; then
        echo -e "${GREEN}✅ Database connection successful${NC}"
    else
        echo -e "${RED}❌ Database connection failed${NC}"
    fi
    
    # Test Ollama connection
    echo -e "${YELLOW}🤖 Testing Ollama connection...${NC}"
    sleep 30  # Wait for Ollama to start
    if curl -s http://${OLLAMA_PUBLIC_IP}:11434/api/tags > /dev/null; then
        echo -e "${GREEN}✅ Ollama connection successful${NC}"
    else
        echo -e "${RED}❌ Ollama connection failed${NC}"
    fi
    
    # Test DynamoDB
    echo -e "${YELLOW}📊 Testing DynamoDB...${NC}"
    if aws dynamodb list-tables --region ${REGION} | grep -q "development-search-indexes"; then
        echo -e "${GREEN}✅ DynamoDB tables created successfully${NC}"
    else
        echo -e "${RED}❌ DynamoDB tables not found${NC}"
    fi
}

# Create development guide
create_dev_guide() {
    echo -e "${YELLOW}📚 Creating development guide...${NC}"
    
    cat > cloud-development-guide.md << EOF
# Cloud Development Guide

## 🎯 Overview

This setup provides a **cloud-based development environment** where:
- **Code runs locally** on your machine
- **Database is in AWS RDS** (PostgreSQL)
- **AI model is in AWS EC2** (Ollama)
- **File storage is in AWS S3**
- **Search indexes are in AWS DynamoDB**

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

## 🔧 Configuration

### Environment Variables (.env.cloud-dev)
- **Database**: AWS RDS PostgreSQL
- **AI**: AWS EC2 Ollama
- **Storage**: AWS S3
- **Search**: AWS DynamoDB
- **Cache**: Local Redis

### Service Endpoints
- **Database**: ${DATABASE_ENDPOINT}:${DATABASE_PORT}
- **Ollama**: http://${OLLAMA_PUBLIC_IP}:11434
- **S3**: ${S3_BUCKET}
- **DynamoDB**: AWS managed

## 🚀 Quick Start

1. **Copy environment configuration**:
   \`\`\`bash
   cp .env.cloud-dev .env
   \`\`\`

2. **Activate virtual environment**:
   \`\`\`bash
   source match/bin/activate
   \`\`\`

3. **Install dependencies**:
   \`\`\`bash
   pip install -r requirements.txt
   \`\`\`

4. **Run migrations**:
   \`\`\`bash
   python manage.py migrate
   \`\`\`

5. **Create superuser**:
   \`\`\`bash
   python manage.py createsuperuser
   \`\`\`

6. **Start the application**:
   \`\`\`bash
   python manage.py runserver
   \`\`\`

## 🧪 Testing

### Database Connection
\`\`\`bash
# Test PostgreSQL connection
psql -U postgres -d recruitment_portal -h ${DATABASE_ENDPOINT} -p ${DATABASE_PORT}
\`\`\`

### Ollama Connection
\`\`\`bash
# Test Ollama API
curl http://${OLLAMA_PUBLIC_IP}:11434/api/tags
\`\`\`

### DynamoDB Connection
\`\`\`bash
# List tables
aws dynamodb list-tables --region ${REGION}

# Test table access
aws dynamodb scan --table-name development-search-indexes --region ${REGION}
\`\`\`

## 💰 Cost Optimization

### Development Costs
- **RDS**: ~$15-20/month (t3.micro)
- **EC2**: ~$30-40/month (t3.medium)
- **DynamoDB**: ~$5-10/month (pay-per-request)
- **S3**: ~$1-5/month (minimal usage)
- **Total**: ~$50-75/month

### Cost Saving Tips
1. **Stop EC2 when not in use** (save ~70% of EC2 costs)
2. **Use RDS reserved instances** for long-term development
3. **Monitor DynamoDB usage** and optimize queries
4. **Clean up S3 objects** regularly

## 🔒 Security

### Network Security
- **RDS**: Publicly accessible for development (not recommended for production)
- **EC2**: Public IP with security group allowing 11434 and 22
- **DynamoDB**: AWS managed with IAM access

### Access Control
- **Database**: Username/password authentication
- **EC2**: SSH key pair for direct access
- **AWS Services**: IAM credentials

## 🚨 Troubleshooting

### Database Connection Issues
\`\`\`bash
# Check if RDS is accessible
telnet ${DATABASE_ENDPOINT} ${DATABASE_PORT}

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
\`\`\`

### Ollama Connection Issues
\`\`\`bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids i-xxxxxxxxx

# SSH into EC2 to check Ollama
ssh -i ~/.ssh/development-recruitment-portal-key.pem ec2-user@${OLLAMA_PUBLIC_IP}
\`\`\`

### DynamoDB Issues
\`\`\`bash
# Check table status
aws dynamodb describe-table --table-name development-search-indexes --region ${REGION}
\`\`\`

## 📊 Monitoring

### CloudWatch Metrics
- **RDS**: Database connections, CPU, memory
- **EC2**: CPU, memory, network
- **DynamoDB**: Read/write capacity

### Application Logs
- **Django**: Local log files
- **AWS**: CloudWatch logs for EC2

## 🔄 Development Workflow

1. **Code locally** in your IDE
2. **Connect to AWS services** via environment variables
3. **Test with real data** in AWS
4. **Deploy to production** when ready

## 🎯 Benefits

✅ **No local database setup** - AWS RDS handles everything
✅ **No local AI model** - AWS EC2 runs Ollama
✅ **Consistent environment** - Same services for all developers
✅ **Production-like testing** - Real AWS services
✅ **Easy scaling** - AWS handles infrastructure
✅ **Cost effective** - Pay only for what you use

## 📚 Next Steps

1. **Set up local Redis** for caching
2. **Configure your IDE** for remote debugging
3. **Set up monitoring** and alerts
4. **Create backup strategies** for development data
5. **Plan production deployment**

---

**🎉 Your cloud development environment is ready!**
EOF

    echo -e "${GREEN}✅ Development guide created: cloud-development-guide.md${NC}"
}

# Main execution
main() {
    check_prerequisites
    create_dev_template
    deploy_infrastructure
    get_stack_outputs
    create_dev_config
    test_connections
    create_dev_guide
    
    echo -e "${GREEN}🎉 Cloud development environment setup completed!${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "1. Copy .env.cloud-dev to your project root as .env"
    echo -e "2. Activate your virtual environment: source match/bin/activate"
    echo -e "3. Run migrations: python manage.py migrate"
    echo -e "4. Start the application: python manage.py runserver"
    echo -e ""
    echo -e "${GREEN}📚 Check cloud-development-guide.md for detailed instructions${NC}"
    echo -e "${YELLOW}💰 Estimated monthly cost: $50-75${NC}"
}

# Run main function
main 