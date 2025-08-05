import uuid
import os
from django.db import models
from django.conf import settings
from django.core.files.storage import default_storage


def resume_file_path(instance, filename):
    """Generate file path for resume uploads."""
    ext = filename.split('.')[-1]
    filename = f"{instance.id}.{ext}"
    return os.path.join('resumes', filename)


class Resume(models.Model):
    """Model for storing resume files and processed data."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    candidate = models.ForeignKey('candidates.CandidateProfile', on_delete=models.CASCADE, related_name='resumes')
    
    # File information
    file = models.FileField(upload_to=resume_file_path)
    original_filename = models.CharField(max_length=255)
    file_size = models.PositiveIntegerField(default=0)
    file_type = models.CharField(max_length=10)  # pdf, docx, doc
    
    # Content
    content = models.TextField(blank=True)  # Extracted text content
    processed_data = models.JSONField(default=dict, blank=True)  # Structured data
    
    # Processing status
    is_processed = models.BooleanField(default=False)
    processing_error = models.TextField(blank=True)
    
    # Approval workflow
    is_approved = models.BooleanField(default=False)
    auto_merge_date = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey('auth.User', on_delete=models.SET_NULL, null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    # Metadata
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'resumes'
        ordering = ['-uploaded_at']
        indexes = [
            models.Index(fields=['candidate']),
            models.Index(fields=['is_processed']),
            models.Index(fields=['is_approved']),
            models.Index(fields=['uploaded_at']),
        ]
    
    def __str__(self):
        return f"Resume for {self.candidate.name} ({self.original_filename})"
    
    def save(self, *args, **kwargs):
        # Set file size
        if self.file and not self.file_size:
            self.file_size = self.file.size
        
        # Set auto-merge date if not set
        if not self.auto_merge_date and not self.is_approved:
            from django.utils import timezone
            from datetime import timedelta
            from django.conf import settings
            self.auto_merge_date = timezone.now() + timedelta(hours=settings.AUTO_MERGE_HOURS)
        
        super().save(*args, **kwargs)
    
    def delete(self, *args, **kwargs):
        # Delete file from storage
        if self.file:
            default_storage.delete(self.file.name)
        super().delete(*args, **kwargs)
    
    @property
    def file_url(self):
        """Get the URL for the resume file."""
        if self.file:
            return self.file.url
        return None
    
    @property
    def is_auto_merge_due(self):
        """Check if auto-merge is due."""
        if self.auto_merge_date and not self.is_approved:
            from django.utils import timezone
            return timezone.now() >= self.auto_merge_date
        return False


class ResumeProcessingLog(models.Model):
    """Model for tracking resume processing activities."""
    
    PROCESSING_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    resume = models.ForeignKey(Resume, on_delete=models.CASCADE, related_name='processing_logs')
    
    # Processing details
    status = models.CharField(max_length=20, choices=PROCESSING_STATUS_CHOICES, default='pending')
    error_message = models.TextField(blank=True)
    processing_duration = models.FloatField(default=0.0)  # in seconds
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'resume_processing_logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['resume', 'status']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Processing log for {self.resume} - {self.status}" 