import React from 'react';
import { Link } from 'react-router-dom';
import { User, Mail, Clock, Star, MapPin, Briefcase, Sparkles } from 'lucide-react';

const CandidateCard = ({ candidate, showJobAnalysis = false }) => {
  const {
    id,
    name,
    email,
    title,
    skills = [],
    experience_years,
    registration_days,
    match_score,
    job_match_score,
    job_analysis,
  } = candidate;

  const getScoreColor = (score) => {
    if (score >= 80) return 'text-green-600 bg-green-100 border-green-200';
    if (score >= 60) return 'text-yellow-600 bg-yellow-100 border-yellow-200';
    return 'text-red-600 bg-red-100 border-red-200';
  };

  const getScoreIcon = (score) => {
    if (score >= 80) return <Sparkles className="w-4 h-4" />;
    if (score >= 60) return <Star className="w-4 h-4" />;
    return <Star className="w-4 h-4" />;
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 hover:shadow-lg hover:border-gray-300 transition-all duration-200 overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-gray-100">
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-gradient-to-r from-teal-400 via-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-sm">
              <User className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">{name}</h3>
              <p className="text-sm text-gray-600">{title}</p>
            </div>
          </div>
          
          {/* Match Score */}
          <div className="text-right">
            <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${getScoreColor(match_score)}`}>
              <span className="mr-1">{getScoreIcon(match_score)}</span>
              {match_score}%
            </div>
            {showJobAnalysis && job_match_score && (
              <div className={`mt-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border ${getScoreColor(job_match_score)}`}>
                Job: {job_match_score}%
              </div>
            )}
          </div>
        </div>

        {/* Contact Info */}
        <div className="flex items-center space-x-4 text-sm text-gray-600">
          <div className="flex items-center space-x-1">
            <Mail className="w-4 h-4" />
            <span className="truncate">{email}</span>
          </div>
          <div className="flex items-center space-x-1">
            <Clock className="w-4 h-4" />
            <span>{registration_days} days</span>
          </div>
        </div>
      </div>

      {/* Skills */}
      {skills.length > 0 && (
        <div className="p-6 border-b border-gray-100">
          <h4 className="text-sm font-medium text-gray-700 mb-3">Skills</h4>
          <div className="flex flex-wrap gap-2">
            {skills.slice(0, 5).map((skill, index) => (
              <span
                key={index}
                className="px-3 py-1 bg-gradient-to-r from-blue-50 to-purple-50 text-blue-700 text-xs rounded-full border border-blue-200"
              >
                {skill}
              </span>
            ))}
            {skills.length > 5 && (
              <span className="px-3 py-1 bg-gray-50 text-gray-600 text-xs rounded-full border border-gray-200">
                +{skills.length - 5} more
              </span>
            )}
          </div>
        </div>
      )}

      {/* Job Analysis */}
      {showJobAnalysis && job_analysis && (
        <div className="p-6 border-b border-gray-100">
          <h4 className="text-sm font-medium text-gray-700 mb-3">Job Analysis</h4>
          
          {job_analysis.reasoning && (
            <p className="text-sm text-gray-600 mb-3 leading-relaxed">{job_analysis.reasoning}</p>
          )}
          
          {job_analysis.key_matches && job_analysis.key_matches.length > 0 && (
            <div className="mb-3">
              <h5 className="text-xs font-medium text-green-700 mb-2">Key Matches</h5>
              <div className="flex flex-wrap gap-1">
                {job_analysis.key_matches.map((match, index) => (
                  <span
                    key={index}
                    className="px-2 py-1 bg-green-50 text-green-700 text-xs rounded-md border border-green-200"
                  >
                    {match}
                  </span>
                ))}
              </div>
            </div>
          )}
          
          {job_analysis.missing_skills && job_analysis.missing_skills.length > 0 && (
            <div>
              <h5 className="text-xs font-medium text-orange-700 mb-2">Missing Skills</h5>
              <div className="flex flex-wrap gap-1">
                {job_analysis.missing_skills.map((skill, index) => (
                  <span
                    key={index}
                    className="px-2 py-1 bg-orange-50 text-orange-700 text-xs rounded-md border border-orange-200"
                  >
                    {skill}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Footer */}
      <div className="p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4 text-sm text-gray-600">
            <div className="flex items-center space-x-1">
              <Briefcase className="w-4 h-4" />
              <span>{experience_years} years exp.</span>
            </div>
          </div>
          
          <Link
            to={`/candidate/${id}`}
            className="inline-flex items-center px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white text-sm font-medium rounded-lg hover:from-blue-600 hover:to-purple-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all shadow-sm"
          >
            View Profile
          </Link>
        </div>
      </div>
    </div>
  );
};

export default CandidateCard; 