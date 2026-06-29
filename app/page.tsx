import React from 'react';

export default function Home() {
  return (
    <main style={{
      minHeight: '100vh',
      background: 'radial-gradient(circle at top right, #1e1b4b, #0f172a)',
      color: '#f8fafc',
      fontFamily: '"Outfit", "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '2rem 1rem',
      margin: 0,
    }}>
      <div style={{
        maxWidth: '700px',
        width: '100%',
        background: 'rgba(30, 41, 59, 0.5)',
        backdropFilter: 'blur(12px)',
        border: '1px solid rgba(255, 255, 255, 0.08)',
        borderRadius: '24px',
        padding: '3rem 2.5rem',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.3)',
        textAlign: 'center',
      }}>
        {/* Glow effect */}
        <div style={{
          width: '80px',
          height: '80px',
          borderRadius: '50%',
          background: 'linear-gradient(135deg, #6366f1, #3b82f6)',
          margin: '0 auto 1.5rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 0 30px rgba(99, 102, 241, 0.4)',
        }}>
          <span style={{ fontSize: '2.5rem' }}>📰</span>
        </div>

        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 800,
          margin: '0 0 0.5rem 0',
          background: 'linear-gradient(135deg, #a5b4fc, #818cf8, #60a5fa)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          letterSpacing: '-0.025em',
        }}>
          Newstler API Backend
        </h1>
        
        <p style={{
          color: '#94a3b8',
          fontSize: '1.1rem',
          margin: '0 0 2.5rem 0',
          lineHeight: '1.6',
        }}>
          A high-performance Next.js and Vercel backend aggregator for Flutter clients. Serves news, scrapes content metadata, and proxies APIs with optimized caching.
        </p>

        <div style={{
          textAlign: 'left',
          display: 'flex',
          flexDirection: 'column',
          gap: '1rem',
        }}>
          <h2 style={{
            fontSize: '1.2rem',
            fontWeight: 600,
            color: '#c7d2fe',
            margin: '0 0 0.5rem 0',
            borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
            paddingBottom: '0.5rem',
          }}>
            Available Endpoints
          </h2>

          <a href="/health" style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '1rem 1.25rem',
            background: 'rgba(255, 255, 255, 0.02)',
            border: '1px solid rgba(255, 255, 255, 0.04)',
            borderRadius: '12px',
            textDecoration: 'none',
            color: 'inherit',
            transition: 'all 0.2s ease',
          }}>
            <div>
              <span style={{
                fontSize: '0.75rem',
                fontWeight: 700,
                background: '#10b981',
                color: '#042f1a',
                padding: '0.25rem 0.5rem',
                borderRadius: '6px',
                marginRight: '0.75rem',
                verticalAlign: 'middle'
              }}>GET</span>
              <code style={{ fontSize: '0.95rem', color: '#cbd5e1', verticalAlign: 'middle' }}>/health</code>
            </div>
            <span style={{ fontSize: '0.85rem', color: '#64748b' }}>Health status & timestamp</span>
          </a>

          <a href="/news" style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '1rem 1.25rem',
            background: 'rgba(255, 255, 255, 0.02)',
            border: '1px solid rgba(255, 255, 255, 0.04)',
            borderRadius: '12px',
            textDecoration: 'none',
            color: 'inherit',
            transition: 'all 0.2s ease',
          }}>
            <div>
              <span style={{
                fontSize: '0.75rem',
                fontWeight: 700,
                background: '#10b981',
                color: '#042f1a',
                padding: '0.25rem 0.5rem',
                borderRadius: '6px',
                marginRight: '0.75rem',
                verticalAlign: 'middle'
              }}>GET</span>
              <code style={{ fontSize: '0.95rem', color: '#cbd5e1', verticalAlign: 'middle' }}>/news</code>
            </div>
            <span style={{ fontSize: '0.85rem', color: '#64748b' }}>Google News RSS feed aggregator</span>
          </a>

          <a href="/article?url=https://github.com" style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '1rem 1.25rem',
            background: 'rgba(255, 255, 255, 0.02)',
            border: '1px solid rgba(255, 255, 255, 0.04)',
            borderRadius: '12px',
            textDecoration: 'none',
            color: 'inherit',
            transition: 'all 0.2s ease',
          }}>
            <div>
              <span style={{
                fontSize: '0.75rem',
                fontWeight: 700,
                background: '#10b981',
                color: '#042f1a',
                padding: '0.25rem 0.5rem',
                borderRadius: '6px',
                marginRight: '0.75rem',
                verticalAlign: 'middle'
              }}>GET</span>
              <code style={{ fontSize: '0.95rem', color: '#cbd5e1', verticalAlign: 'middle' }}>/article</code>
            </div>
            <span style={{ fontSize: '0.85rem', color: '#64748b' }}>Metadata & content scraper</span>
          </a>

          <a href="/guardian" style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '1rem 1.25rem',
            background: 'rgba(255, 255, 255, 0.02)',
            border: '1px solid rgba(255, 255, 255, 0.04)',
            borderRadius: '12px',
            textDecoration: 'none',
            color: 'inherit',
            transition: 'all 0.2s ease',
          }}>
            <div>
              <span style={{
                fontSize: '0.75rem',
                fontWeight: 700,
                background: '#10b981',
                color: '#042f1a',
                padding: '0.25rem 0.5rem',
                borderRadius: '6px',
                marginRight: '0.75rem',
                verticalAlign: 'middle'
              }}>GET</span>
              <code style={{ fontSize: '0.95rem', color: '#cbd5e1', verticalAlign: 'middle' }}>/guardian</code>
            </div>
            <span style={{ fontSize: '0.85rem', color: '#64748b' }}>The Guardian API client proxy</span>
          </a>
        </div>

        <div style={{
          marginTop: '2.5rem',
          fontSize: '0.85rem',
          color: '#475569',
        }}>
          Powered by Next.js &middot; Deployable to Vercel
        </div>
      </div>
    </main>
  );
}
