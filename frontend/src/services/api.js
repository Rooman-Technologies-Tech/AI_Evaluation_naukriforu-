import axios from 'axios';

// Create axios instance
const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for authentication
api.interceptors.request.use((config) => {
  // Add auth token if available
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized access
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Search API
export const searchCandidates = async (params) => {
  const response = await api.post('/search/candidates/', params);
  return response.data;
};

export const getCandidateDetails = async (candidateId) => {
  const response = await api.get(`/search/candidate_details/?candidate_id=${candidateId}`);
  return response.data;
};

// Job Descriptions API
export const getJobDescriptions = async () => {
  const response = await api.get('/jobs/active/');
  return response.data;
};

export const createJobDescription = async (jobData) => {
  const response = await api.post('/jobs/', jobData);
  return response.data;
};

export const updateJobDescription = async ({ id, ...jobData }) => {
  const response = await api.put(`/jobs/${id}/`, jobData);
  return response.data;
};

export const deleteJobDescription = async (id) => {
  const response = await api.delete(`/jobs/${id}/`);
  return response.data;
};

// Candidates API
export const getCandidates = async (params = {}) => {
  const response = await api.get('/candidates/', { params });
  return response.data;
};

export const getCandidate = async (id) => {
  const response = await api.get(`/candidates/${id}/`);
  return response.data;
};

export const updateCandidate = async ({ id, ...candidateData }) => {
  const response = await api.put(`/candidates/${id}/`, candidateData);
  return response.data;
};

// Resumes API
export const getResumes = async (params = {}) => {
  const response = await api.get('/resumes/', { params });
  return response.data;
};

export const uploadResume = async (formData) => {
  const response = await api.post('/resumes/', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

export const approveResume = async (id) => {
  const response = await api.post(`/resumes/${id}/approve/`);
  return response.data;
};

export const rejectResume = async (id) => {
  const response = await api.post(`/resumes/${id}/reject/`);
  return response.data;
};

// Resume Updates API
export const getResumeUpdates = async () => {
  const response = await api.get('/resume-updates/pending/');
  return response.data;
};

// File upload helper
export const uploadFile = async (file, onProgress) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await api.post('/resumes/', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    onUploadProgress: (progressEvent) => {
      if (onProgress) {
        const percentCompleted = Math.round(
          (progressEvent.loaded * 100) / progressEvent.total
        );
        onProgress(percentCompleted);
      }
    },
  });

  return response.data;
};

export default api; 