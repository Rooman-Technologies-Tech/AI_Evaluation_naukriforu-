from rest_framework import serializers
from candidates.models import CandidateProfile, CandidateUpdate
from jobs.models import JobDescription
from resumes.models import Resume


class CandidateProfileSerializer(serializers.ModelSerializer):
    """Serializer for candidate profiles."""
    
    registration_days = serializers.ReadOnlyField()
    
    class Meta:
        model = CandidateProfile
        fields = [
            'id', 'name', 'email', 'phone', 'title', 'location',
            'linkedin_url', 'github_url', 'website_url', 'skills',
            'experience_years', 'registration_date', 'registration_days',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'registration_date', 'registration_days', 'created_at', 'updated_at']


class CandidateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for candidate updates."""
    
    candidate_name = serializers.CharField(source='candidate.name', read_only=True)
    
    class Meta:
        model = CandidateUpdate
        fields = [
            'id', 'candidate', 'candidate_name', 'update_type',
            'old_data', 'new_data', 'status', 'auto_merge_date',
            'approved_by', 'approved_at', 'created_at'
        ]
        read_only_fields = ['id', 'created_at', 'approved_at']


class JobDescriptionSerializer(serializers.ModelSerializer):
    """Serializer for job descriptions."""
    
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = JobDescription
        fields = [
            'id', 'title', 'company', 'location', 'description',
            'requirements', 'responsibilities', 'job_type',
            'experience_level', 'salary_range', 'is_active',
            'is_featured', 'created_by', 'created_by_name',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']


class ResumeSerializer(serializers.ModelSerializer):
    """Serializer for resumes."""
    
    candidate_name = serializers.CharField(source='candidate.name', read_only=True)
    candidate_email = serializers.CharField(source='candidate.email', read_only=True)
    file_url = serializers.ReadOnlyField()
    is_auto_merge_due = serializers.ReadOnlyField()
    
    class Meta:
        model = Resume
        fields = [
            'id', 'candidate', 'candidate_name', 'candidate_email',
            'file', 'original_filename', 'file_size', 'file_type',
            'content', 'processed_data', 'is_processed', 'processing_error',
            'is_approved', 'auto_merge_date', 'approved_by', 'approved_at',
            'uploaded_at', 'updated_at', 'file_url', 'is_auto_merge_due'
        ]
        read_only_fields = [
            'id', 'file_size', 'is_processed', 'processing_error',
            'uploaded_at', 'updated_at', 'file_url', 'is_auto_merge_due'
        ]


class ResumeUpdateSerializer(serializers.ModelSerializer):
    """Serializer for resume updates."""
    
    candidate_name = serializers.CharField(source='candidate.name', read_only=True)
    candidate_email = serializers.CharField(source='candidate.email', read_only=True)
    file_url = serializers.ReadOnlyField()
    is_auto_merge_due = serializers.ReadOnlyField()
    
    class Meta:
        model = Resume
        fields = [
            'id', 'candidate', 'candidate_name', 'candidate_email',
            'original_filename', 'file_size', 'file_type', 'uploaded_at',
            'auto_merge_date', 'file_url', 'is_auto_merge_due'
        ]
        read_only_fields = [
            'id', 'file_size', 'uploaded_at', 'file_url', 'is_auto_merge_due'
        ]


class SearchResultSerializer(serializers.Serializer):
    """Serializer for search results."""
    
    id = serializers.CharField()
    name = serializers.CharField()
    email = serializers.CharField()
    title = serializers.CharField()
    skills = serializers.ListField(child=serializers.CharField())
    experience_years = serializers.IntegerField()
    registration_days = serializers.IntegerField()
    match_score = serializers.FloatField()
    job_match_score = serializers.FloatField(required=False)
    job_analysis = serializers.DictField(required=False)
    content = serializers.CharField(required=False)
    resume_id = serializers.CharField(required=False)


class SearchRequestSerializer(serializers.Serializer):
    """Serializer for search requests."""
    
    query = serializers.CharField(max_length=1000)
    job_description_id = serializers.CharField(required=False, allow_null=True)
    limit = serializers.IntegerField(default=20, min_value=1, max_value=100)


class SearchResponseSerializer(serializers.Serializer):
    """Serializer for search responses."""
    
    query = serializers.CharField()
    results = SearchResultSerializer(many=True)
    total_results = serializers.IntegerField()
    job_description_id = serializers.CharField(required=False, allow_null=True) 