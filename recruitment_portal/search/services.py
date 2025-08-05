import logging
from typing import List, Dict, Any, Optional
from django.db.models import Q
from django.conf import settings
from django.core.cache import cache

from candidates.models import CandidateProfile
from jobs.models import JobDescription
from resumes.models import Resume
from ai.providers import AIProviderFactory

logger = logging.getLogger(__name__)


class SearchService:
    """Service for AI-powered candidate search."""
    
    def __init__(self, provider_type: str = None):
        self.ai_provider = AIProviderFactory.get_provider(provider_type)
    
    async def search_candidates(
        self, 
        query: str, 
        job_description_id: Optional[str] = None,
        limit: int = 20
    ) -> Dict[str, Any]:
        """
        Search candidates using natural language query.
        
        Args:
            query: Natural language search query
            job_description_id: Optional job description ID for filtering
            limit: Maximum number of results to return
            
        Returns:
            Dictionary containing search results and metadata
        """
        try:
            # Get active candidates
            candidates = CandidateProfile.objects.filter(is_active=True)
            
            # Prepare candidate data for AI search
            candidate_data = []
            for candidate in candidates:
                # Get latest resume
                latest_resume = candidate.resumes.filter(is_processed=True).first()
                
                candidate_info = {
                    'id': str(candidate.id),
                    'name': candidate.name,
                    'email': candidate.email,
                    'title': candidate.title,
                    'skills': candidate.skills,
                    'experience_years': candidate.experience_years,
                    'registration_days': candidate.registration_days,
                    'content': '',
                    'embedding': None
                }
                
                # Add resume content if available
                if latest_resume and latest_resume.content:
                    candidate_info['content'] = latest_resume.content
                    candidate_info['resume_id'] = str(latest_resume.id)
                
                candidate_data.append(candidate_info)
            
            # Generate embeddings for candidates
            for candidate in candidate_data:
                if candidate['content']:
                    try:
                        embedding = await self.ai_provider.embed(candidate['content'])
                        candidate['embedding'] = embedding
                    except Exception as e:
                        logger.warning(f"Failed to generate embedding for candidate {candidate['id']}: {e}")
            
            # Perform AI search
            search_results = await self.ai_provider.search(query, candidate_data)
            
            # Apply job description filtering if provided
            if job_description_id:
                try:
                    job_description = JobDescription.objects.get(id=job_description_id)
                    search_results = await self._filter_by_job_description(
                        search_results, job_description
                    )
                except JobDescription.DoesNotExist:
                    logger.warning(f"Job description {job_description_id} not found")
            
            # Limit results
            search_results = search_results[:limit]
            
            # Calculate match scores
            for result in search_results:
                result['match_score'] = round(result.get('similarity_score', 0) * 100, 1)
            
            return {
                'query': query,
                'results': search_results,
                'total_results': len(search_results),
                'job_description_id': job_description_id
            }
            
        except Exception as e:
            logger.error(f"Search error: {e}")
            raise
    
    async def _filter_by_job_description(
        self, 
        candidates: List[Dict], 
        job_description: JobDescription
    ) -> List[Dict]:
        """
        Filter candidates based on job description requirements.
        """
        try:
            # Create job description prompt
            job_prompt = f"""
            Job Title: {job_description.title}
            Company: {job_description.company}
            Description: {job_description.description}
            Requirements: {job_description.requirements}
            
            Please analyze the following candidate and provide a match score (0-100) 
            based on how well they fit this job description.
            """
            
            filtered_candidates = []
            
            for candidate in candidates:
                if candidate['content']:
                    # Create candidate prompt
                    candidate_prompt = f"""
                    Candidate Information:
                    Name: {candidate['name']}
                    Title: {candidate['title']}
                    Skills: {candidate['skills']}
                    Experience: {candidate['experience_years']} years
                    Resume Content: {candidate['content'][:1000]}...
                    
                    {job_prompt}
                    
                    Please provide a JSON response with:
                    {{
                        "match_score": <score 0-100>,
                        "reasoning": "<brief explanation>",
                        "key_matches": ["<skill1>", "<skill2>"],
                        "missing_skills": ["<skill1>", "<skill2>"]
                    }}
                    """
                    
                    try:
                        # Get AI analysis
                        ai_response = await self.ai_provider.generate(candidate_prompt)
                        
                        # Parse response (basic parsing - in production, use proper JSON parsing)
                        import json
                        try:
                            analysis = json.loads(ai_response)
                            candidate['job_analysis'] = analysis
                            candidate['job_match_score'] = analysis.get('match_score', 0)
                        except json.JSONDecodeError:
                            # Fallback to similarity score
                            candidate['job_match_score'] = candidate.get('similarity_score', 0) * 100
                        
                        filtered_candidates.append(candidate)
                        
                    except Exception as e:
                        logger.warning(f"Failed to analyze candidate {candidate['id']}: {e}")
                        # Keep candidate with default score
                        candidate['job_match_score'] = candidate.get('similarity_score', 0) * 100
                        filtered_candidates.append(candidate)
            
            # Sort by job match score
            filtered_candidates.sort(key=lambda x: x.get('job_match_score', 0), reverse=True)
            
            return filtered_candidates
            
        except Exception as e:
            logger.error(f"Job description filtering error: {e}")
            return candidates
    
    async def get_candidate_details(self, candidate_id: str) -> Dict[str, Any]:
        """
        Get detailed information about a candidate.
        """
        try:
            candidate = CandidateProfile.objects.get(id=candidate_id)
            
            # Get all resumes
            resumes = candidate.resumes.filter(is_processed=True).order_by('-uploaded_at')
            
            # Get recent updates
            updates = candidate.updates.filter(status='pending').order_by('-created_at')
            
            return {
                'id': str(candidate.id),
                'name': candidate.name,
                'email': candidate.email,
                'phone': candidate.phone,
                'title': candidate.title,
                'location': candidate.location,
                'skills': candidate.skills,
                'experience_years': candidate.experience_years,
                'registration_date': candidate.registration_date.isoformat(),
                'registration_days': candidate.registration_days,
                'linkedin_url': candidate.linkedin_url,
                'github_url': candidate.github_url,
                'website_url': candidate.website_url,
                'resumes': [
                    {
                        'id': str(resume.id),
                        'filename': resume.original_filename,
                        'uploaded_at': resume.uploaded_at.isoformat(),
                        'is_approved': resume.is_approved,
                        'file_url': resume.file_url
                    }
                    for resume in resumes
                ],
                'pending_updates': [
                    {
                        'id': str(update.id),
                        'update_type': update.update_type,
                        'created_at': update.created_at.isoformat(),
                        'auto_merge_date': update.auto_merge_date.isoformat() if update.auto_merge_date else None
                    }
                    for update in updates
                ]
            }
            
        except CandidateProfile.DoesNotExist:
            raise ValueError(f"Candidate {candidate_id} not found")
        except Exception as e:
            logger.error(f"Error getting candidate details: {e}")
            raise 