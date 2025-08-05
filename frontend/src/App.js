import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import './App.css';

// Components
import Header from './components/Header';
import HomePage from './pages/HomePage';
import JobDescriptionPage from './pages/JobDescriptionPage';
import ResumeUpdatesPage from './pages/ResumeUpdatesPage';
import CandidateDetailsPage from './pages/CandidateDetailsPage';

// Create a client
const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <div className="App">
          <Header />
          <main>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/job-description" element={<JobDescriptionPage />} />
              <Route path="/resume-updates" element={<ResumeUpdatesPage />} />
              <Route path="/candidate/:id" element={<CandidateDetailsPage />} />
            </Routes>
          </main>
        </div>
      </Router>
    </QueryClientProvider>
  );
}

export default App; 