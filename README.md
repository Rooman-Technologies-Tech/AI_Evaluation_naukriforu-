# AI-Powered Recruitment Portal

A centralized AI-powered recruitment portal designed to manage and intelligently search through a master database of candidate profiles and resumes. Built with Django backend, React frontend, and integrated with Ollama and AWS Bedrock for AI capabilities.

## 🎨 Modern UI Design

The portal features a **Canva AI-inspired interface** with:
- **Gradient-bordered search input** with prominent AI interaction area
- **Organized action buttons** for different search types (Find for me, Analyze profiles, Generate report, Match skills)
- **Clean, modern navigation** with pill-shaped tabs
- **Card-based results display** with smooth animations and hover effects
- **Responsive design** that works across all devices
- **Accessibility features** including reduced motion support and high contrast mode

## 🚀 Features

### 🔍 **Natural Language Search**
- Claude-style search bar for intuitive candidate queries
- AI-powered semantic search using Ollama (local) and AWS Bedrock (production)
- Real-time candidate matching with percentage scores
- Job description filtering for targeted searches

### 📋 **Job Description Management**
- Upload and manage job descriptions via dedicated page
- AI-powered candidate-job matching with detailed analysis
- Match scoring with reasoning and skill gap analysis

### 📄 **Resume Update Tracking**
- Automatic detection of resume updates from existing candidates
- Manual approval or automatic merging after 24 hours
- Email/phone-based candidate identification
- Registration duration tracking

### 👥 **Candidate Profile Management**
- Comprehensive candidate profiles with skills, experience, and contact info
- Registration duration tracking and display
- Profile update history and approval workflow

## 📋 Prerequisites

- Python 3.12+
- Node.js 18+
- PostgreSQL 13+
- Redis 6+
- Ollama (for local AI development)
- AWS Account (for production deployment)

## 🛠️ Installation

### Backend Setup
```bash
cd recruitment_portal
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### Frontend Setup
```bash
cd frontend
npm install
npm start
```

## 🔧 Configuration

Create a `.env` file in the `recruitment_portal` directory:

```env
# Django Settings
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DB_NAME=recruitment_portal
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432

# AI Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama2
AI_PROVIDER=ollama  # or 'bedrock' for production

# AWS Settings (for production)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=your-bucket-name
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL=anthropic.claude-3-sonnet-20240229-v1:0

# Redis
REDIS_URL=redis://localhost:6379/0
```

## 🚀 Usage

### 1. **Natural Language Search**
- Enter queries like "Senior developers with React and Node.js experience"
- Use action buttons for quick searches: "Find for me", "Analyze profiles", etc.
- Select job descriptions to filter results with AI-powered matching

### 2. **Job Description Management**
- Navigate to Job Descriptions page
- Upload and manage job postings
- Use job descriptions to filter candidate searches

### 3. **Resume Updates**
- Check the Resume Updates page for new candidate submissions
- Approve or reject updates manually
- Automatic merging after 24 hours

## 🏗️ Architecture

### **Backend (Django)**
- **Django REST Framework** for API endpoints
- **PostgreSQL** for primary data storage
- **Redis** for caching and Celery task queue
- **Celery** for background tasks (resume processing, auto-merge)
- **Ollama/Bedrock** for AI capabilities

### **Frontend (React)**
- **React 18** with modern hooks
- **React Query** for data fetching and caching
- **React Router** for navigation
- **Tailwind CSS** for styling
- **Lucide React** for icons

### **AI Integration**
- **Ollama** for local development (llama2 model)
- **AWS Bedrock** for production (Claude 3 Sonnet)
- **Vector similarity search** for candidate matching
- **Natural language processing** for query understanding

## 🚀 AWS Deployment

### **Infrastructure (CloudFormation)**
- **ECS Fargate** for containerized backend
- **Application Load Balancer** for traffic distribution
- **RDS PostgreSQL** for database
- **ElastiCache Redis** for caching
- **S3** for file storage
- **CloudWatch** for monitoring

### **Deployment Steps**
1. Build and push Docker images to ECR
2. Deploy CloudFormation stack
3. Configure environment variables
4. Set up CI/CD pipeline

## 🔍 API Endpoints

### **Search**
- `POST /api/search/candidates/` - AI-powered candidate search
- `GET /api/search/candidate-details/{id}/` - Get candidate details

### **Candidates**
- `GET /api/candidates/` - List candidates
- `GET /api/candidates/{id}/` - Get candidate
- `PUT /api/candidates/{id}/` - Update candidate
- `POST /api/candidates/{id}/update-profile/` - Create update request

### **Jobs**
- `GET /api/jobs/` - List job descriptions
- `POST /api/jobs/` - Create job description
- `PUT /api/jobs/{id}/` - Update job description
- `DELETE /api/jobs/{id}/` - Delete job description

### **Resumes**
- `GET /api/resumes/` - List resumes
- `POST /api/resumes/` - Upload resume
- `POST /api/resumes/{id}/approve/` - Approve resume
- `POST /api/resumes/{id}/reject/` - Reject resume

### **Resume Updates**
- `GET /api/resume-updates/` - List pending updates
- `GET /api/resume-updates/pending/` - Get pending updates count

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the docs folder for detailed guides
- **Issues**: Report bugs and feature requests via GitHub Issues
- **Discussions**: Join community discussions on GitHub

## 🔮 Roadmap

### **Phase 1** ✅
- [x] Basic Django backend with models
- [x] AI integration (Ollama/Bedrock)
- [x] React frontend with modern UI
- [x] Natural language search
- [x] Job description management

### **Phase 2** 🚧
- [ ] Advanced candidate analytics
- [ ] Email notifications
- [ ] Bulk operations
- [ ] Advanced filtering options

### **Phase 3** 📋
- [ ] Mobile app
- [ ] Advanced AI features
- [ ] Integration with job boards
- [ ] Advanced reporting

## 🙏 Acknowledgments

- **Ollama** for local AI capabilities
- **AWS Bedrock** for production AI services
- **Django** and **React** communities
- **Tailwind CSS** for the beautiful design system

---

**Built with ❤️ for modern recruitment workflows** 