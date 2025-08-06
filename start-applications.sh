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
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}   Creating Python virtual environment...${NC}"
    $PYTHON_CMD -m venv venv
fi

source venv/bin/activate
pip install -q -r requirements.txt

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