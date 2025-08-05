"""
API URL configuration for recruitment portal.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    SearchViewSet,
    CandidateViewSet,
    JobDescriptionViewSet,
    ResumeViewSet,
    ResumeUpdateViewSet,
)

# Create router and register viewsets
router = DefaultRouter()
router.register(r'search', SearchViewSet, basename='search')
router.register(r'candidates', CandidateViewSet, basename='candidates')
router.register(r'jobs', JobDescriptionViewSet, basename='jobs')
router.register(r'resumes', ResumeViewSet, basename='resumes')
router.register(r'resume-updates', ResumeUpdateViewSet, basename='resume-updates')

urlpatterns = [
    path('', include(router.urls)),
] 