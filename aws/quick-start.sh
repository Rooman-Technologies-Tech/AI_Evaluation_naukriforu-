#!/bin/bash

# Quick Start Script for Recruitment Portal
# This script provides a complete setup for both local and AWS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Recruitment Portal - Quick Start Setup${NC}"
echo -e "${YELLOW}==========================================${NC}"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 is not installed${NC}"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed${NC}"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites are installed${NC}"
}

# Function to setup local development
setup_local() {
    echo -e "${YELLOW}🔧 Setting up local development environment...${NC}"
    
    # Run local setup script
    ./local-setup.sh
    
    echo -e "${GREEN}✅ Local development environment ready!${NC}"
}

# Function to setup AWS production
setup_aws() {
    echo -e "${YELLOW}☁️  Setting up AWS production environment...${NC}"
    
    # Get AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    
    # Run deployment script
    ./deploy.sh development us-east-1 "RecruitmentPortal123!"
    
    echo -e "${GREEN}✅ AWS production environment ready!${NC}"
}

# Function to start the application
start_application() {
    echo -e "${YELLOW}🎯 Starting the application...${NC}"
    
    cd ..
    
    # Activate virtual environment
    source match/bin/activate
    
    # Copy environment file
    if [ -f ".env.local" ]; then
        cp .env.local .env
        echo -e "${GREEN}✅ Using local environment configuration${NC}"
    elif [ -f ".env.production" ]; then
        cp .env.production .env
        echo -e "${GREEN}✅ Using production environment configuration${NC}"
    else
        echo -e "${RED}❌ No environment configuration found${NC}"
        exit 1
    fi
    
    # Run migrations
    echo -e "${YELLOW}📊 Running database migrations...${NC}"
    python manage.py migrate
    
    # Create superuser if not exists
    echo -e "${YELLOW}👤 Creating superuser...${NC}"
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin123') if not User.objects.filter(username='admin').exists() else None" | python manage.py shell
    
    echo -e "${GREEN}✅ Application setup completed!${NC}"
    echo -e "${BLUE}🎉 Your recruitment portal is ready!${NC}"
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo -e "1. Start Django server: python manage.py runserver"
    echo -e "2. Start React frontend: cd frontend && npm start"
    echo -e "3. Access the application: http://localhost:3000"
    echo -e "4. Admin panel: http://localhost:8000/admin"
    echo -e "   Username: admin"
    echo -e "   Password: admin123"
}

# Main menu
show_menu() {
    echo -e "${BLUE}Choose your setup option:${NC}"
    echo -e "${YELLOW}1.${NC} Local Development Setup"
    echo -e "${YELLOW}2.${NC} AWS Production Setup"
    echo -e "${YELLOW}3.${NC} Complete Setup (Local + AWS)"
    echo -e "${YELLOW}4.${NC} Start Application Only"
    echo -e "${YELLOW}5.${NC} Exit"
    echo ""
    read -p "Enter your choice (1-5): " choice
}

# Main execution
main() {
    check_prerequisites
    
    while true; do
        show_menu
        
        case $choice in
            1)
                setup_local
                start_application
                break
                ;;
            2)
                setup_aws
                start_application
                break
                ;;
            3)
                setup_local
                setup_aws
                start_application
                break
                ;;
            4)
                start_application
                break
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