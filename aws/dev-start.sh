#!/bin/bash

# Developer Start Script for Cloud Development
# This script helps developers quickly start the application with AWS services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Developer Start Script${NC}"
echo -e "${YELLOW}========================${NC}"

# Check if environment file exists
if [ ! -f "../.env.cloud-dev" ]; then
    echo -e "${RED}❌ Cloud development environment not set up.${NC}"
    echo -e "${YELLOW}Please run the cloud setup first:${NC}"
    echo -e "cd aws && ./cloud-dev-setup.sh"
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 is not installed${NC}"
        exit 1
    fi
    
    # Check if virtual environment exists
    if [ ! -d "../match" ]; then
        echo -e "${RED}❌ Virtual environment 'match' not found${NC}"
        echo -e "${YELLOW}Please create the virtual environment first${NC}"
        exit 1
    fi
    
    # Check if requirements.txt exists
    if [ ! -f "../recruitment_portal/requirements.txt" ]; then
        echo -e "${RED}❌ requirements.txt not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites verified${NC}"
}

# Function to setup environment
setup_environment() {
    echo -e "${YELLOW}🔧 Setting up environment...${NC}"
    
    cd ..
    
    # Copy environment configuration
    if [ -f ".env.cloud-dev" ]; then
        cp .env.cloud-dev .env
        echo -e "${GREEN}✅ Environment configuration copied${NC}"
    else
        echo -e "${RED}❌ .env.cloud-dev not found${NC}"
        exit 1
    fi
    
    # Activate virtual environment
    source match/bin/activate
    echo -e "${GREEN}✅ Virtual environment activated${NC}"
    
    # Install dependencies if needed
    if [ ! -d "match/lib/python3.11/site-packages/django" ]; then
        echo -e "${YELLOW}📦 Installing dependencies...${NC}"
        pip install -r recruitment_portal/requirements.txt
        echo -e "${GREEN}✅ Dependencies installed${NC}"
    else
        echo -e "${GREEN}✅ Dependencies already installed${NC}"
    fi
}

# Function to setup database
setup_database() {
    echo -e "${YELLOW}📊 Setting up database...${NC}"
    
    # Run migrations
    python recruitment_portal/manage.py migrate
    echo -e "${GREEN}✅ Database migrations completed${NC}"
    
    # Create superuser if not exists
    echo -e "${YELLOW}👤 Creating superuser...${NC}"
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin123') if not User.objects.filter(username='admin').exists() else None" | python recruitment_portal/manage.py shell
    echo -e "${GREEN}✅ Superuser created/verified${NC}"
}

# Function to start services
start_services() {
    echo -e "${YELLOW}🚀 Starting services...${NC}"
    
    # Start Redis if not running
    if ! redis-cli ping > /dev/null 2>&1; then
        echo -e "${YELLOW}🔴 Starting Redis...${NC}"
        sudo systemctl start redis-server 2>/dev/null || echo -e "${YELLOW}⚠️  Redis not started (may need manual start)${NC}"
    else
        echo -e "${GREEN}✅ Redis is running${NC}"
    fi
}

# Function to start application
start_application() {
    echo -e "${YELLOW}🎯 Starting application...${NC}"
    
    echo -e "${GREEN}🎉 Application is ready!${NC}"
    echo -e "${BLUE}📋 Access URLs:${NC}"
    echo -e "${YELLOW}Frontend:${NC} http://localhost:3000"
    echo -e "${YELLOW}Backend API:${NC} http://localhost:8000"
    echo -e "${YELLOW}Admin Panel:${NC} http://localhost:8000/admin"
    echo -e "${YELLOW}Admin Credentials:${NC} admin / admin123"
    echo -e ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "1. Start Django server: python recruitment_portal/manage.py runserver"
    echo -e "2. Start React frontend: cd frontend && npm start"
    echo -e ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo -e "- The application connects to AWS RDS PostgreSQL"
    echo -e "- AI features use AWS EC2 Ollama"
    echo -e "- File storage uses AWS S3"
    echo -e "- Search indexes use AWS DynamoDB"
    echo -e ""
    echo -e "${GREEN}🚀 Ready to develop!${NC}"
}

# Function to show menu
show_menu() {
    echo -e "${BLUE}Choose an option:${NC}"
    echo -e "${YELLOW}1.${NC} Setup and start everything"
    echo -e "${YELLOW}2.${NC} Setup environment only"
    echo -e "${YELLOW}3.${NC} Run migrations only"
    echo -e "${YELLOW}4.${NC} Show connection info"
    echo -e "${YELLOW}5.${NC} Exit"
    echo ""
    read -p "Enter your choice (1-5): " choice
}

# Function to show connection info
show_connection_info() {
    echo -e "${BLUE}📊 Connection Information${NC}"
    echo -e "${YELLOW}========================${NC}"
    
    if [ -f ".env" ]; then
        echo -e "${GREEN}✅ Environment file found${NC}"
        
        # Extract connection info from .env
        DB_HOST=$(grep "DB_HOST=" .env | cut -d'=' -f2)
        DB_PORT=$(grep "DB_PORT=" .env | cut -d'=' -f2)
        OLLAMA_HOST=$(grep "OLLAMA_HOST=" .env | cut -d'=' -f2)
        S3_BUCKET=$(grep "AWS_STORAGE_BUCKET_NAME=" .env | cut -d'=' -f2)
        
        echo -e "${YELLOW}Database:${NC} ${DB_HOST}:${DB_PORT}"
        echo -e "${YELLOW}Ollama:${NC} ${OLLAMA_HOST}"
        echo -e "${YELLOW}S3 Bucket:${NC} ${S3_BUCKET}"
        echo -e "${YELLOW}DynamoDB:${NC} AWS managed"
        
        echo -e ""
        echo -e "${BLUE}🧪 Test Commands:${NC}"
        echo -e "Database: psql -U postgres -d recruitment_portal -h ${DB_HOST} -p ${DB_PORT}"
        echo -e "Ollama: curl ${OLLAMA_HOST}/api/tags"
        echo -e "DynamoDB: aws dynamodb list-tables --region us-east-1"
    else
        echo -e "${RED}❌ Environment file not found${NC}"
    fi
}

# Main execution
main() {
    check_prerequisites
    
    while true; do
        show_menu
        
        case $choice in
            1)
                setup_environment
                setup_database
                start_services
                start_application
                break
                ;;
            2)
                setup_environment
                echo -e "${GREEN}✅ Environment setup completed${NC}"
                break
                ;;
            3)
                setup_environment
                setup_database
                echo -e "${GREEN}✅ Database setup completed${NC}"
                break
                ;;
            4)
                show_connection_info
                ;;
            5)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please try again.${NC}"
                ;;
        esac
    done
}

# Run main function
main 