"""
API URL configuration for recruitment portal.
"""
from django.urls import path, include
from django.http import JsonResponse
from rest_framework.routers import DefaultRouter

from .views import (
    SearchViewSet,
    CandidateViewSet,
    JobDescriptionViewSet,
    ResumeViewSet,
    ResumeUpdateViewSet,
)

def health_check(request):
    """Simple health check endpoint."""
    return JsonResponse({"status": "healthy", "message": "API is running"})

# Create router and register viewsets
router = DefaultRouter()
router.register(r'search', SearchViewSet, basename='search')
router.register(r'candidates', CandidateViewSet, basename='candidates')
router.register(r'jobs', JobDescriptionViewSet, basename='jobs')
router.register(r'resumes', ResumeViewSet, basename='resumes')
router.register(r'resume-updates', ResumeUpdateViewSet, basename='resume-updates')

urlpatterns = [
    path('health/', health_check, name='health_check'),
    path('', include(router.urls)),
] 