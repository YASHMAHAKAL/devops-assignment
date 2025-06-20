'use client';

import { useEffect, useState } from 'react';

export default function Home() {
  const [message, setMessage] = useState('');

  useEffect(() => {
    fetch('http://localhost:8000/api/message')
      .then(res => res.json())
      .then(data => setMessage(data.message))
      .catch(() => setMessage('Failed to fetch backend message.'));
  }, []);

  return (
    <main style={{ textAlign: 'center', marginTop: '50px' }}>
      <h1>Frontend (Next.js)</h1>
      <h2>Message from Backend:</h2>
      <p>{message}</p>
    </main>
  );
}
