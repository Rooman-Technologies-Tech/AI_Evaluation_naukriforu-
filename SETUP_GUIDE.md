# Setup Guide - AI-Powered Recruitment Portal

This guide will walk you through setting up and running the recruitment portal application step by step.

## Prerequisites

Before starting, ensure you have the following installed:

### Required Software
- **Python 3.12+** - [Download here](https://www.python.org/downloads/)
- **Node.js 18+** - [Download here](https://nodejs.org/)
- **PostgreSQL 13+** - [Download here](https://www.postgresql.org/download/)
- **Redis 6+** - [Download here](https://redis.io/download)
- **Git** - [Download here](https://git-scm.com/)

### Optional (for local AI)
- **Ollama** - [Download here](https://ollama.ai/)

## Step-by-Step Setup

### Step 1: Clone and Navigate to Project
```bash
# Navigate to your project directory
cd C:\Users\manju\

# Verify you're in the correct directory
dir
```

### Step 2: Backend Setup (Django)

#### 2.1 Create Virtual Environment
```bash
# Navigate to backend directory
cd recruitment_portal

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
# source venv/bin/activate
```

#### 2.2 Install Python Dependencies
```bash
# Install requirements
pip install -r requirements.txt
```

#### 2.3 Configure Environment Variables
Create a `.env` file in the `recruitment_portal` directory:

```bash
# Create .env file
echo "" > .env
```

Edit the `.env` file with your configuration:

```env
# Django Settings
SECRET_KEY=your-super-secret-key-change-this-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration
DB_NAME=recruitment_portal
DB_USER=postgres
DB_PASSWORD=your_postgres_password
DB_HOST=localhost
DB_PORT=5432

# AI Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama2
AI_PROVIDER=ollama

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Auto-merge settings
AUTO_MERGE_HOURS=24
```

#### 2.4 Set Up PostgreSQL Database
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE recruitment_portal;

# Create user (if needed)
CREATE USER recruitment_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE recruitment_portal TO recruitment_user;

# Exit PostgreSQL
\q
```

#### 2.5 Run Django Migrations
```bash
# Make sure virtual environment is activated
# venv\Scripts\activate (Windows)

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
# Follow the prompts to create admin user
```

#### 2.6 Start Django Development Server
```bash
# Start the backend server
python manage.py runserver

# You should see output like:
# Watching for file changes with StatReloader
# Performing system checks...
# System check identified no issues (0 silenced).
# Django version 5.0.2, using settings 'core.settings'
# Starting development server at http://127.0.0.1:8000/
# Quit the server with CONTROL-C.
```

### Step 3: Frontend Setup (React)

#### 3.1 Open New Terminal Window
Keep the Django server running and open a new terminal window.

#### 3.2 Navigate to Frontend Directory
```bash
# Navigate to frontend directory
cd frontend

# Install Node.js dependencies
npm install
```

#### 3.3 Start React Development Server
```bash
# Start the frontend development server
npm start

# You should see output like:
# Compiled successfully!
# You can now view recruitment-portal-frontend in the browser.
# Local:            http://localhost:3000
# On Your Network:  http://192.168.x.x:3000
```

### Step 4: Set Up Redis (Optional for Development)

#### 4.1 Install Redis
**Windows:**
```bash
# Download Redis for Windows from: https://github.com/microsoftarchive/redis/releases
# Or use WSL2 with Redis

# Start Redis server
redis-server
```

**macOS:**
```bash
# Install with Homebrew
brew install redis

# Start Redis
brew services start redis
```

**Linux:**
```bash
# Install Redis
sudo apt-get install redis-server

# Start Redis
sudo systemctl start redis-server
```

### Step 5: Set Up Ollama (Optional for Local AI)

#### 5.1 Install Ollama
```bash
# Download and install from: https://ollama.ai/
# Or use curl (macOS/Linux):
curl -fsSL https://ollama.ai/install.sh | sh
```

#### 5.2 Pull AI Model
```bash
# Pull the llama2 model
ollama pull llama2

# Start Ollama service
ollama serve
```

## 🚀 Running the Application

### Complete Startup Sequence

1. **Start Redis** (if using):
   ```bash
   redis-server
   ```

2. **Start Ollama** (if using local AI):
   ```bash
   ollama serve
   ```

3. **Start Django Backend**:
   ```bash
   cd recruitment_portal
   venv\Scripts\activate
   python manage.py runserver
   ```

4. **Start React Frontend** (new terminal):
   ```bash
   cd frontend
   npm start
   ```

### Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Django Admin**: http://localhost:8000/admin

## 🔧 Configuration Options

### Environment Variables Explained

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Django secret key | Auto-generated |
| `DEBUG` | Enable debug mode | True |
| `DB_NAME` | PostgreSQL database name | recruitment_portal |
| `DB_USER` | PostgreSQL username | postgres |
| `DB_PASSWORD` | PostgreSQL password | (required) |
| `OLLAMA_HOST` | Ollama server URL | http://localhost:11434 |
| `OLLAMA_MODEL` | AI model name | llama2 |
| `AI_PROVIDER` | AI provider (ollama/bedrock) | ollama |
| `REDIS_URL` | Redis connection URL | redis://localhost:6379/0 |

### Switching AI Providers

**For Local Development (Ollama):**
```env
AI_PROVIDER=ollama
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama2
```

**For Production (AWS Bedrock):**
```env
AI_PROVIDER=bedrock
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL=anthropic.claude-3-sonnet-20240229-v1:0
```

## 🧪 Testing the Application

### 1. Test Backend API
```bash
# Test health endpoint
curl http://localhost:8000/api/

# Test admin interface
# Open http://localhost:8000/admin in browser
```

### 2. Test Frontend
- Open http://localhost:3000
- Try the search functionality
- Navigate between different pages
- Test the Canva AI-inspired interface

### 3. Test AI Integration
```bash
# Test Ollama (if using local AI)
curl http://localhost:11434/api/tags
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Database Connection Error
```bash
# Check PostgreSQL is running
# Windows: Check Services app
# macOS: brew services list
# Linux: sudo systemctl status postgresql

# Test connection
psql -U postgres -d recruitment_portal
```

#### 2. Redis Connection Error
```bash
# Check Redis is running
redis-cli ping
# Should return: PONG
```

#### 3. Ollama Connection Error
```bash
# Check Ollama is running
curl http://localhost:11434/api/tags
# Should return available models
```

#### 4. Frontend Build Errors
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### 5. Django Migration Errors
```bash
# Reset migrations (if needed)
python manage.py migrate --fake-initial

# Or start fresh
python manage.py flush
python manage.py migrate
```

### Port Conflicts

If you get port conflicts:

**Django (8000):**
```bash
python manage.py runserver 8001
```

**React (3000):**
```bash
PORT=3001 npm start
```

**Redis (6379):**
```bash
redis-server --port 6380
```

## 📱 Development Workflow

### Making Changes

1. **Backend Changes**:
   - Edit files in `recruitment_portal/`
   - Django will auto-reload
   - Check http://localhost:8000/admin

2. **Frontend Changes**:
   - Edit files in `frontend/src/`
   - React will auto-reload
   - Check http://localhost:3000

3. **Database Changes**:
   ```bash
   # Create new migration
   python manage.py makemigrations

   # Apply migration
   python manage.py migrate
   ```

### Adding New Features

1. **Backend API**:
   - Add models in `recruitment_portal/[app]/models.py`
   - Add views in `recruitment_portal/[app]/views.py`
   - Add URLs in `recruitment_portal/api/urls.py`

2. **Frontend Components**:
   - Add components in `frontend/src/components/`
   - Add pages in `frontend/src/pages/`
   - Update routing in `frontend/src/App.js`

## 🚀 Production Deployment

For production deployment, see the `aws/deployment.yaml` file and the deployment section in the main README.md.

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Check the console logs for error messages
4. Ensure all services are running (PostgreSQL, Redis, Ollama)

---

**🎉 Your AI-powered recruitment portal is now ready to use!** 