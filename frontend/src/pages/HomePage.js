import React, { useState } from 'react';
import { useMutation, useQuery } from 'react-query';
import { Search, Users, Clock, Star, FileText, Sparkles, User, Briefcase, Code, Image, FileText as DocIcon, Mic, ArrowRight, Plus } from 'lucide-react';
import { searchCandidates, getJobDescriptions } from '../services/api';
import CandidateCard from '../components/CandidateCard';
import JobDescriptionDropdown from '../components/JobDescriptionDropdown';

const HomePage = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedJobId, setSelectedJobId] = useState('');
  const [searchResults, setSearchResults] = useState(null);

  // Get job descriptions for dropdown
  const { data: jobDescriptions = [] } = useQuery(
    'jobDescriptions',
    getJobDescriptions,
    {
      refetchOnWindowFocus: false,
    }
  );

  // Search mutation
  const searchMutation = useMutation(searchCandidates, {
    onSuccess: (data) => {
      setSearchResults(data);
    },
    onError: (error) => {
      console.error('Search error:', error);
      alert('Search failed. Please try again.');
    },
  });

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;

    searchMutation.mutate({
      query: searchQuery,
      job_description_id: selectedJobId || null,
      limit: 20,
    });
  };

  const handleJobSelect = (jobId) => {
    setSelectedJobId(jobId);
  };

  const handleExampleClick = (query) => {
    setSearchQuery(query);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50">
      {/* Top Navigation Bar */}
      <div className="bg-white bg-opacity-60 backdrop-blur-lg border-b border-white border-opacity-20 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-center py-6">
            <div className="flex space-x-1 bg-white bg-opacity-70 backdrop-blur-md rounded-2xl p-1.5 shadow-lg border border-white border-opacity-30">
              <button className="flex items-center space-x-2 px-5 py-2.5 rounded-xl text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-white hover:bg-opacity-80 transition-all">
                <Briefcase className="w-4 h-4" />
                <span>Your candidates</span>
              </button>
              <button className="flex items-center space-x-2 px-5 py-2.5 rounded-xl text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-white hover:bg-opacity-80 transition-all">
                <FileText className="w-4 h-4" />
                <span>Job descriptions</span>
              </button>
              <button className="flex items-center space-x-2 px-5 py-2.5 rounded-xl text-sm font-medium bg-white text-purple-700 shadow-sm border border-purple-200 bg-opacity-90">
                <Sparkles className="w-4 h-4" />
                <span>Recruitment AI</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Main AI Interaction Area */}
        <div className="max-w-4xl mx-auto mb-12">
          <form onSubmit={handleSearch}>
            {/* Gradient-bordered input box */}
            <div className="relative p-1 bg-gradient-to-r from-purple-400 via-indigo-500 to-blue-600 rounded-3xl shadow-2xl">
              <div className="bg-white rounded-2xl p-8 backdrop-blur-sm">
                <div className="flex items-center space-x-4 mb-6">
                  <button
                    type="button"
                    className="p-2 text-gray-400 hover:text-gray-600 transition-colors rounded-xl hover:bg-gray-50"
                  >
                    <Plus className="w-6 h-6" />
                  </button>
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Describe your ideal candidate, and I'll find the perfect matches"
                    className="flex-1 text-xl text-gray-900 placeholder-gray-400 focus:outline-none font-light"
                  />
                  <div className="flex items-center space-x-2">
                    <button
                      type="button"
                      className="p-3 text-gray-400 hover:text-purple-600 transition-colors rounded-xl hover:bg-purple-50"
                    >
                      <Sparkles className="w-6 h-6" />
                    </button>
                    <button
                      type="button"
                      className="p-3 text-gray-400 hover:text-purple-600 transition-colors rounded-xl hover:bg-purple-50"
                    >
                      <Mic className="w-6 h-6" />
                    </button>
                    <button
                      type="submit"
                      disabled={searchMutation.isLoading || !searchQuery.trim()}
                      className="p-3 text-gray-400 hover:text-purple-600 transition-colors disabled:opacity-50 rounded-xl hover:bg-purple-50"
                    >
                      <ArrowRight className="w-6 h-6" />
                    </button>
                  </div>
                </div>

                {/* Action buttons */}
                <div className="flex flex-wrap gap-4">
                  <button
                    type="button"
                    onClick={() => handleExampleClick("Senior developers with React and Node.js experience")}
                    className="flex items-center space-x-3 px-6 py-3 bg-gradient-to-r from-purple-500 to-purple-600 text-white rounded-2xl text-sm font-medium hover:from-purple-600 hover:to-purple-700 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
                  >
                    <Sparkles className="w-5 h-5" />
                    <span>Find for me</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleExampleClick("Data scientists with Python and machine learning")}
                    className="flex items-center space-x-3 px-6 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-2xl text-sm font-medium hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
                  >
                    <Image className="w-5 h-5" />
                    <span>Analyze profiles</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleExampleClick("Product managers with 5+ years experience")}
                    className="flex items-center space-x-3 px-6 py-3 bg-gradient-to-r from-green-500 to-emerald-600 text-white rounded-2xl text-sm font-medium hover:from-green-600 hover:to-emerald-700 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
                  >
                    <DocIcon className="w-5 h-5" />
                    <span>Generate report</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleExampleClick("DevOps engineers with AWS and Kubernetes")}
                    className="flex items-center space-x-3 px-6 py-3 bg-gradient-to-r from-orange-500 to-pink-600 text-white rounded-2xl text-sm font-medium hover:from-orange-600 hover:to-pink-700 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
                  >
                    <Code className="w-5 h-5" />
                    <span>Match skills</span>
                  </button>
                </div>
              </div>
            </div>
          </form>

          {/* Disclaimer */}
          <div className="text-center mt-4">
            <p className="text-sm text-gray-500">
              Recruitment AI can make mistakes. Please verify candidate information. 
              <a href="#" className="text-purple-600 hover:text-purple-700 ml-1">See terms</a> • 
              <a href="#" className="text-purple-600 hover:text-purple-700 ml-1">Give feedback</a>
            </p>
          </div>
        </div>

        {/* Job Description Filter */}
        {jobDescriptions.length > 0 && (
          <div className="max-w-4xl mx-auto mb-8">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center space-x-4">
                <label className="text-sm font-medium text-gray-700">
                  Filter by Job Description:
                </label>
                <JobDescriptionDropdown
                  jobDescriptions={jobDescriptions}
                  selectedJobId={selectedJobId}
                  onSelect={handleJobSelect}
                />
              </div>
            </div>
          </div>
        )}

        {/* Search Results */}
        {searchResults && (
          <div className="space-y-6">
            {/* Results Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <h2 className="text-2xl font-bold text-gray-900">
                  Search Results
                </h2>
                <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
                  {searchResults.total_results} candidates found
                </span>
              </div>
              
              {selectedJobId && (
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <FileText className="w-4 h-4" />
                  <span>Filtered by job description</span>
                </div>
              )}
            </div>

            {/* Results Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {searchResults.results.map((candidate) => (
                <CandidateCard
                  key={candidate.id}
                  candidate={candidate}
                  showJobAnalysis={!!selectedJobId}
                />
              ))}
            </div>

            {searchResults.results.length === 0 && (
              <div className="text-center py-12">
                <Users className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  No candidates found
                </h3>
                <p className="text-gray-600">
                  Try adjusting your search criteria or job description filter.
                </p>
              </div>
            )}
          </div>
        )}

        {/* Example Queries Section */}
        {!searchResults && (
          <div className="mt-16">
            <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">
              See what you can do with AI
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                {
                  title: "Code",
                  description: "Senior developers with React and Node.js experience",
                  color: "emerald",
                  icon: Code,
                  gradient: "from-emerald-400 to-green-500"
                },
                {
                  title: "Analyze",
                  description: "Data scientists with Python and machine learning",
                  color: "blue",
                  icon: Image,
                  gradient: "from-blue-400 to-indigo-500"
                },
                {
                  title: "Management",
                  description: "Product managers with 5+ years experience",
                  color: "purple",
                  icon: DocIcon,
                  gradient: "from-purple-400 to-pink-500"
                },
                {
                  title: "Frontend",
                  description: "Frontend developers with TypeScript and modern frameworks",
                  color: "orange",
                  icon: Sparkles,
                  gradient: "from-orange-400 to-red-500"
                },
                {
                  title: "DevOps",
                  description: "DevOps engineers with AWS and Kubernetes",
                  color: "cyan",
                  icon: Image,
                  gradient: "from-cyan-400 to-blue-500"
                }
              ].map((example, index) => {
                const Icon = example.icon;
                
                return (
                  <button
                    key={index}
                    onClick={() => handleExampleClick(example.description)}
                    className="text-left p-8 bg-white bg-opacity-60 backdrop-blur-md border border-white border-opacity-30 rounded-2xl hover:bg-opacity-80 hover:shadow-2xl transition-all duration-300 group transform hover:-translate-y-1 shadow-lg"
                  >
                    <div className="flex items-center space-x-4 mb-4">
                      <span className={`px-3 py-1.5 rounded-2xl text-sm font-medium text-white bg-gradient-to-r ${example.gradient} shadow-md`}>
                        {example.title}
                      </span>
                      <Icon className="w-5 h-5 text-gray-500 group-hover:text-gray-700 transition-colors" />
                    </div>
                    <p className="text-gray-700 group-hover:text-gray-900 font-medium leading-relaxed">{example.description}</p>
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default HomePage; 