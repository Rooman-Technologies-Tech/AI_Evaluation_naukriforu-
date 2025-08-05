import uuid
from django.db import models
from django.contrib.auth.models import User


class JobDescription(models.Model):
    """Model for storing job descriptions."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    company = models.CharField(max_length=255)
    location = models.CharField(max_length=255, blank=True)
    description = models.TextField()
    requirements = models.JSONField(default=list, blank=True)
    responsibilities = models.JSONField(default=list, blank=True)
    
    # Job details
    job_type = models.CharField(max_length=50, blank=True)  # Full-time, Part-time, Contract
    experience_level = models.CharField(max_length=50, blank=True)  # Entry, Mid, Senior
    salary_range = models.CharField(max_length=100, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    # Metadata
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'job_descriptions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['title']),
            models.Index(fields=['company']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} at {self.company}"
    
    @property
    def keywords(self):
        """Extract keywords from job description and requirements."""
        keywords = []
        
        # Add title keywords
        keywords.extend(self.title.lower().split())
        
        # Add requirements keywords
        for requirement in self.requirements:
            if isinstance(requirement, str):
                keywords.extend(requirement.lower().split())
        
        # Add description keywords (basic extraction)
        description_words = self.description.lower().split()
        keywords.extend([word for word in description_words if len(word) > 3])
        
        return list(set(keywords))  # Remove duplicates


class JobSearch(models.Model):
    """Model for storing search queries and results."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    query = models.TextField()
    job_description = models.ForeignKey(JobDescription, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Search results
    results_count = models.PositiveIntegerField(default=0)
    search_duration = models.FloatField(default=0.0)  # in seconds
    
    # Metadata
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'job_searches'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['created_at']),
            models.Index(fields=['created_by']),
        ]
    
    def __str__(self):
        return f"Search: {self.query[:50]}... ({self.created_at})" 