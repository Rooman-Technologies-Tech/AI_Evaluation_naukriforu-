import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Search, FileText, Users, Settings, Sparkles } from 'lucide-react';

const Header = () => {
  const location = useLocation();

  const navItems = [
    { path: '/', label: 'Search', icon: Search },
    { path: '/job-description', label: 'Job Descriptions', icon: FileText },
    { path: '/resume-updates', label: 'Resume Updates', icon: Users },
  ];

  return (
    <header className="bg-gradient-to-r from-purple-600 via-blue-600 to-indigo-700 shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-20">
          <div className="flex items-center">
            <Link to="/" className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-white bg-opacity-20 backdrop-blur rounded-2xl flex items-center justify-center shadow-lg border border-white border-opacity-30">
                <Sparkles className="w-7 h-7 text-white" />
              </div>
              <div>
                <span className="text-2xl font-bold text-white">Recruitment Portal</span>
                <span className="block text-sm text-purple-100">AI-Powered Search</span>
              </div>
            </Link>
          </div>

          <nav className="hidden md:flex space-x-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;

              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200 ${
                    isActive
                      ? 'bg-white bg-opacity-20 text-white shadow-sm border border-white border-opacity-30 backdrop-blur'
                      : 'text-purple-100 hover:text-white hover:bg-white hover:bg-opacity-10'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          <div className="flex items-center space-x-3">
            <button className="p-2 text-purple-100 hover:text-white hover:bg-white hover:bg-opacity-10 rounded-xl transition-all duration-200">
              <Settings className="w-5 h-5" />
            </button>
            <div className="w-8 h-8 bg-white bg-opacity-20 backdrop-blur rounded-full flex items-center justify-center border border-white border-opacity-30">
              <span className="text-white text-sm font-medium">A</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header; 