#!/bin/bash

# Recruitment Portal - Start Frontend and Backend Applications
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_PORT=8000
FRONTEND_PORT=3000
MAX_RETRIES=30
RETRY_INTERVAL=2
AWS_REGION="ap-south-1"

echo -e "${BLUE}🚀 Starting Recruitment Portal Applications${NC}"
echo "=============================================="

# Function to check if port is in use
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 0  # Port is in use
    else
        return 1  # Port is available
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local retries=0
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        
        retries=$((retries + 1))
        echo -e "${YELLOW}   Attempt $retries/$MAX_RETRIES - waiting...${NC}"
        sleep $RETRY_INTERVAL
    done
    
    echo -e "${RED}❌ $service_name failed to start after $MAX_RETRIES attempts${NC}"
    return 1
}

# Function to cleanup processes on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down applications...${NC}"
    
    if [ ! -z "$BACKEND_PID" ]; then
        echo -e "${YELLOW}   Stopping backend (PID: $BACKEND_PID)${NC}"
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        echo -e "${YELLOW}   Stopping frontend (PID: $FRONTEND_PID)${NC}"
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Applications stopped${NC}"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGINT SIGTERM

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

# Check if Python is available
if ! command -v python &> /dev/null; then
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python is not installed${NC}"
        exit 1
    else
        PYTHON_CMD="python3"
    fi
else
    PYTHON_CMD="python"
fi

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    exit 1
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi

# Check if environment files exist
if [ ! -f "recruitment_portal/.env" ]; then
    echo -e "${RED}❌ Backend .env file not found. Please run ./deploy-and-setup.sh first${NC}"
    exit 1
fi

if [ ! -f "frontend/.env" ]; then
    echo -e "${RED}❌ Frontend .env file not found. Please run ./deploy-and-setup.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check if ports are already in use
echo -e "${BLUE}🔍 Checking port availability...${NC}"

if check_port $BACKEND_PORT; then
    echo -e "${RED}❌ Backend port $BACKEND_PORT is already in use${NC}"
    echo -e "${YELLOW}   Kill the process using: sudo lsof -ti:$BACKEND_PORT | xargs kill -9${NC}"
    exit 1
fi

if check_port $FRONTEND_PORT; then
    echo -e "${RED}❌ Frontend port $FRONTEND_PORT is already in use${NC}"
    echo -e "${YELLOW}   Kill the process using: sudo lsof -ti:$FRONTEND_PORT | xargs kill -9${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Ports are available${NC}"

# Install dependencies if needed
echo -e "${BLUE}📦 Checking and installing dependencies...${NC}"

# Backend dependencies
echo -e "${YELLOW}   Checking backend dependencies...${NC}"
cd recruitment_portal

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo -e "${GREEN}   ✅ Virtual environment found, activating...${NC}"
    source venv/bin/activate
    
    # Check Python version in the venv
    VENV_PYTHON_VERSION=$(python --version 2>&1 | grep -o "3\.[0-9][0-9]*")
    echo -e "${BLUE}   Current Python version in venv: $VENV_PYTHON_VERSION${NC}"
    
    if [[ "$VENV_PYTHON_VERSION" == "3.11"* ]]; then
        echo -e "${GREEN}   ✅ Python 3.11.x detected - perfect for this project!${NC}"
    elif [[ "$VENV_PYTHON_VERSION" == "3.10"* ]]; then
        echo -e "${GREEN}   ✅ Python 3.10.x detected - good compatibility!${NC}"
    elif [[ "$VENV_PYTHON_VERSION" == "3.12"* ]]; then
        echo -e "${YELLOW}   ⚠️  Python 3.12.x detected - may have compatibility issues${NC}"
        echo -e "${YELLOW}   Recommended: Use Python 3.11.x for best compatibility${NC}"
    else
        echo -e "${RED}   ❌ Unsupported Python version: $VENV_PYTHON_VERSION${NC}"
        echo -e "${YELLOW}   Please use Python 3.10.x or 3.11.x for best results${NC}"
        exit 1
    fi
    
    # Check if core packages are installed
    if ! python -c "import django" &>/dev/null; then
        echo -e "${YELLOW}   Installing missing dependencies...${NC}"
        pip install -q -r requirements-fixed.txt 2>/dev/null || pip install -q -r requirements.txt
    else
        echo -e "${GREEN}   ✅ Dependencies already installed${NC}"
    fi
else
    echo -e "${YELLOW}   Creating new Python virtual environment...${NC}"
    
    # Try to find Python 3.11 first, then 3.10
    if command -v python3.11 &> /dev/null; then
        PYTHON_CMD="python3.11"
        echo -e "${GREEN}   Using Python 3.11 (recommended)${NC}"
    elif command -v python3.10 &> /dev/null; then
        PYTHON_CMD="python3.10" 
        echo -e "${GREEN}   Using Python 3.10 (good compatibility)${NC}"
    elif command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | grep -o "3\.[0-9][0-9]*")
        if [[ "$PYTHON_VERSION" == "3.11"* ]] || [[ "$PYTHON_VERSION" == "3.10"* ]]; then
            PYTHON_CMD="python3"
            echo -e "${GREEN}   Using system Python $PYTHON_VERSION${NC}"
        else
            echo -e "${YELLOW}   ⚠️  System Python is $PYTHON_VERSION - may have compatibility issues${NC}"
            PYTHON_CMD="python3"
        fi
    else
        echo -e "${RED}   ❌ No suitable Python version found${NC}"
        exit 1
    fi
    
    $PYTHON_CMD -m venv venv
    source venv/bin/activate
    
    # Upgrade core tools first for Python 3.12 compatibility
    pip install -q --upgrade pip setuptools==69.0.0 wheel
    pip install -q -r requirements-fixed.txt 2>/dev/null || pip install -q -r requirements.txt
fi

# Run Django migrations
echo -e "${YELLOW}   Running database migrations...${NC}"
$PYTHON_CMD manage.py migrate --noinput

cd ..

# Frontend dependencies
echo -e "${YELLOW}   Checking frontend dependencies...${NC}"
cd frontend
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}   Installing frontend dependencies...${NC}"
    npm install --silent
fi
cd ..

echo -e "${GREEN}✅ Dependencies are ready${NC}"

# Start applications
echo -e "${BLUE}🎯 Starting applications...${NC}"

# Start backend
echo -e "${YELLOW}   Starting Django backend on port $BACKEND_PORT...${NC}"
cd recruitment_portal
source venv/bin/activate
nohup $PYTHON_CMD manage.py runserver 0.0.0.0:$BACKEND_PORT > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Start frontend  
echo -e "${YELLOW}   Starting React frontend on port $FRONTEND_PORT...${NC}"
cd frontend
nohup npm start > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# Wait for services to be ready
wait_for_service "http://localhost:$BACKEND_PORT/api/health/" "Backend API" || {
    echo -e "${RED}❌ Backend failed to start. Check backend.log for details${NC}"
    cleanup
    exit 1
}

wait_for_service "http://localhost:$FRONTEND_PORT" "Frontend App" || {
    echo -e "${RED}❌ Frontend failed to start. Check frontend.log for details${NC}"
    cleanup  
    exit 1
}

# Success message
echo ""
echo -e "${GREEN}🎉 Both applications started successfully!${NC}"
echo "=========================================="
echo -e "${BLUE}📱 Application URLs:${NC}"
echo -e "   Frontend: ${YELLOW}http://localhost:$FRONTEND_PORT${NC}"
echo -e "   Backend API: ${YELLOW}http://localhost:$BACKEND_PORT${NC}"
echo ""
echo -e "${BLUE}📋 Process Information:${NC}"
echo -e "   Backend PID: ${YELLOW}$BACKEND_PID${NC}"
echo -e "   Frontend PID: ${YELLOW}$FRONTEND_PID${NC}"
echo ""
echo -e "${BLUE}📝 Log Files:${NC}"
echo -e "   Backend: ${YELLOW}backend.log${NC}"
echo -e "   Frontend: ${YELLOW}frontend.log${NC}"
echo ""
echo -e "${YELLOW}💡 Press Ctrl+C to stop both applications${NC}"
echo ""

# Keep the script running and monitor processes
while true; do
    # Check if processes are still running
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${RED}❌ Backend process died unexpectedly${NC}"
        cleanup
        exit 1
    fi
    
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${RED}❌ Frontend process died unexpectedly${NC}"
        cleanup
        exit 1
    fi
    
    sleep 5
done