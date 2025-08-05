import logging
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from candidates.models import CandidateProfile, CandidateUpdate
from jobs.models import JobDescription
from resumes.models import Resume
from search.services import SearchService

logger = logging.getLogger(__name__)


class SearchViewSet(viewsets.ViewSet):
    """ViewSet for AI-powered search functionality."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    @action(detail=False, methods=['post'])
    async def candidates(self, request):
        """
        Search candidates using natural language query.
        
        Expected payload:
        {
            "query": "I need candidates with 2 years of experience in DevOps and Linux",
            "job_description_id": "optional-uuid",
            "limit": 20
        }
        """
        try:
            query = request.data.get('query', '').strip()
            if not query:
                return Response(
                    {'error': 'Query is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            job_description_id = request.data.get('job_description_id')
            limit = request.data.get('limit', 20)
            
            # Initialize search service
            search_service = SearchService()
            
            # Perform search
            results = await search_service.search_candidates(
                query=query,
                job_description_id=job_description_id,
                limit=limit
            )
            
            return Response(results, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Search error: {e}")
            return Response(
                {'error': 'Search failed'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    async def candidate_details(self, request):
        """Get detailed information about a candidate."""
        try:
            candidate_id = request.query_params.get('candidate_id')
            if not candidate_id:
                return Response(
                    {'error': 'candidate_id is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            search_service = SearchService()
            details = await search_service.get_candidate_details(candidate_id)
            
            return Response(details, status=status.HTTP_200_OK)
            
        except ValueError as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error getting candidate details: {e}")
            return Response(
                {'error': 'Failed to get candidate details'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CandidateViewSet(viewsets.ModelViewSet):
    """ViewSet for candidate profile management."""
    
    queryset = CandidateProfile.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_active', 'experience_years']
    search_fields = ['name', 'email', 'title', 'skills']
    ordering_fields = ['registration_date', 'name', 'experience_years']
    ordering = ['-registration_date']
    
    def get_serializer_class(self):
        from .serializers import CandidateProfileSerializer
        return CandidateProfileSerializer
    
    @action(detail=True, methods=['post'])
    def update_profile(self, request, pk=None):
        """Update candidate profile information."""
        try:
            candidate = self.get_object()
            
            # Create update record
            update = CandidateUpdate.objects.create(
                candidate=candidate,
                update_type='profile',
                old_data={
                    'name': candidate.name,
                    'title': candidate.title,
                    'skills': candidate.skills,
                    'experience_years': candidate.experience_years,
                },
                new_data=request.data
            )
            
            return Response({
                'message': 'Profile update created successfully',
                'update_id': str(update.id)
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            logger.error(f"Profile update error: {e}")
            return Response(
                {'error': 'Failed to create profile update'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class JobDescriptionViewSet(viewsets.ModelViewSet):
    """ViewSet for job description management."""
    
    queryset = JobDescription.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_active', 'is_featured', 'job_type', 'experience_level']
    search_fields = ['title', 'company', 'description']
    ordering_fields = ['created_at', 'title', 'company']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        from .serializers import JobDescriptionSerializer
        return JobDescriptionSerializer
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get active job descriptions for dropdown."""
        jobs = self.queryset.filter(is_active=True).values('id', 'title', 'company')
        return Response(jobs, status=status.HTTP_200_OK)


class ResumeViewSet(viewsets.ModelViewSet):
    """ViewSet for resume management."""
    
    queryset = Resume.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['is_processed', 'is_approved', 'candidate']
    ordering_fields = ['uploaded_at']
    ordering = ['-uploaded_at']
    
    def get_serializer_class(self):
        from .serializers import ResumeSerializer
        return ResumeSerializer
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a resume update."""
        try:
            resume = self.get_object()
            resume.is_approved = True
            resume.approved_by = request.user
            resume.save()
            
            return Response({
                'message': 'Resume approved successfully'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Resume approval error: {e}")
            return Response(
                {'error': 'Failed to approve resume'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a resume update."""
        try:
            resume = self.get_object()
            resume.delete()
            
            return Response({
                'message': 'Resume rejected and deleted'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Resume rejection error: {e}")
            return Response(
                {'error': 'Failed to reject resume'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ResumeUpdateViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for resume update tracking."""
    
    queryset = Resume.objects.filter(is_approved=False)
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['candidate', 'is_processed']
    ordering_fields = ['uploaded_at', 'auto_merge_date']
    ordering = ['-uploaded_at']
    
    def get_serializer_class(self):
        from .serializers import ResumeUpdateSerializer
        return ResumeUpdateSerializer
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get pending resume updates."""
        pending_resumes = self.queryset.filter(is_approved=False)
        
        # Check for auto-merge due resumes
        from django.utils import timezone
        auto_merge_due = pending_resumes.filter(
            auto_merge_date__lte=timezone.now()
        )
        
        return Response({
            'pending_count': pending_resumes.count(),
            'auto_merge_due_count': auto_merge_due.count(),
            'resumes': self.get_serializer(pending_resumes, many=True).data
        }, status=status.HTTP_200_OK) 