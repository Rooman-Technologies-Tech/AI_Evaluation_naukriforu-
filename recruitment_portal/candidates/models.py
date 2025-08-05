import uuid
from django.db import models
from django.utils import timezone


class CandidateProfile(models.Model):
    """Model for storing candidate profile information."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, db_index=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    name = models.CharField(max_length=255)
    registration_date = models.DateTimeField(auto_now_add=True)
    last_updated = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    # Profile information
    title = models.CharField(max_length=255, blank=True)
    location = models.CharField(max_length=255, blank=True)
    linkedin_url = models.URLField(blank=True)
    github_url = models.URLField(blank=True)
    website_url = models.URLField(blank=True)
    
    # Skills and experience
    skills = models.JSONField(default=list, blank=True)
    experience_years = models.PositiveIntegerField(default=0)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'candidate_profiles'
        ordering = ['-registration_date']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['registration_date']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.email})"
    
    @property
    def registration_duration(self):
        """Calculate how long the candidate has been registered."""
        return timezone.now() - self.registration_date
    
    @property
    def registration_days(self):
        """Get registration duration in days."""
        return self.registration_duration.days


class CandidateUpdate(models.Model):
    """Model for tracking candidate profile updates."""
    
    UPDATE_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('auto_merged', 'Auto Merged'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    candidate = models.ForeignKey(CandidateProfile, on_delete=models.CASCADE, related_name='updates')
    
    # Update details
    update_type = models.CharField(max_length=50)  # 'resume', 'profile', 'skills', etc.
    old_data = models.JSONField(default=dict, blank=True)
    new_data = models.JSONField(default=dict, blank=True)
    
    # Approval workflow
    status = models.CharField(max_length=20, choices=UPDATE_STATUS_CHOICES, default='pending')
    auto_merge_date = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey('auth.User', on_delete=models.SET_NULL, null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'candidate_updates'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['candidate', 'status']),
            models.Index(fields=['auto_merge_date']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Update for {self.candidate.name} - {self.update_type} ({self.status})"
    
    def save(self, *args, **kwargs):
        # Set auto-merge date if not set
        if not self.auto_merge_date and self.status == 'pending':
            from django.utils import timezone
            from datetime import timedelta
            from django.conf import settings
            self.auto_merge_date = timezone.now() + timedelta(hours=settings.AUTO_MERGE_HOURS)
        super().save(*args, **kwargs) 