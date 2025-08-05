import React, { useState, useRef, useEffect } from 'react';
import { ChevronDown, FileText, X } from 'lucide-react';

const JobDescriptionDropdown = ({ jobDescriptions, selectedJobId, onSelect }) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const selectedJob = jobDescriptions.find(job => job.id === selectedJobId);

  const handleSelect = (jobId) => {
    onSelect(jobId);
    setIsOpen(false);
  };

  const handleClear = (e) => {
    e.stopPropagation();
    onSelect('');
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center justify-between w-full px-4 py-3 text-left bg-white border border-gray-300 rounded-lg shadow-sm hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
      >
        <div className="flex items-center space-x-3">
          <FileText className="w-5 h-5 text-gray-400" />
          <span className={selectedJob ? 'text-gray-900' : 'text-gray-500'}>
            {selectedJob ? selectedJob.title : 'Select a job description...'}
          </span>
        </div>
        <div className="flex items-center space-x-2">
          {selectedJobId && (
            <button
              onClick={handleClear}
              className="p-1 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          )}
          <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
        </div>
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-auto">
          <div className="py-1">
            {jobDescriptions.length === 0 ? (
              <div className="px-4 py-3 text-sm text-gray-500">
                No job descriptions available
              </div>
            ) : (
              jobDescriptions.map((job) => (
                <button
                  key={job.id}
                  onClick={() => handleSelect(job.id)}
                  className={`w-full px-4 py-3 text-left hover:bg-gray-50 transition-colors ${
                    selectedJobId === job.id ? 'bg-blue-50 text-blue-700' : 'text-gray-900'
                  }`}
                >
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0 mt-1">
                      <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm">{job.title}</div>
                      <div className="text-xs text-gray-500 mt-1">
                        {job.company} • {job.location}
                      </div>
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default JobDescriptionDropdown; 