'use client';

import React, { useState } from 'react';

export default function Home() {
  const [url, setUrl] = useState('');
  const [qrImage, setQrImage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const generateQR = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/generate-qr/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url }),
      });
      
      if (!response.ok) throw new Error('Generation failed');
      const data = await response.json();
      setQrImage(data.qr_code_url);
    } catch (err) {
      alert("Error reaching the API. Ensure your backend is running.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen flex items-center justify-center bg-[#f2f2fc] p-4 sm:p-10">
      <div className="w-full max-w-xl bg-[#fdf9ff] rounded-2xl sm:rounded-[2rem] shadow-[0_0_50px_rgba(48,46,77,0.15)] border border-[#e8dfec] overflow-hidden transition-all duration-500">
        <div className="bg-[#825432] py-8 sm:py-12 px-6 sm:px-10 text-center">
          <h1 className="text-2xl sm:text-4xl font-bold text-[#fdf9ff] tracking-tight">QR Generator</h1>
          <p className="text-[#e8dfec] mt-2 sm:mt-3 text-sm sm:text-lg opacity-90">Secure URL-to-Code Conversion</p>
          <p className="text-[#e8dfec] mt-2 sm:mt-3 text-sm sm:text-lg opacity-90">Owner: Filip Ermenkov</p>
        </div>

        <form onSubmit={generateQR} className="p-6 sm:p-12 space-y-6 sm:space-y-8">
          <div className="space-y-2 sm:space-y-3">
            <label className="block text-sm sm:text-md font-semibold text-[#504e70] ml-1">Target URL</label>
            <input
              type="url"
              required
              placeholder="https://example.com"
              className="w-full px-4 sm:px-6 py-3 sm:py-4 rounded-xl border-2 border-[#e8dfec] bg-white text-[#302e4d] text-base sm:text-lg focus:border-[#825432] outline-none transition-all"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#825432] text-white hover:cursor-pointer hover:bg-white hover:text-[#825432] border-2 border-[#825432] font-bold py-3 sm:py-4 rounded-xl text-lg sm:text-xl transition-all duration-300 disabled:opacity-50 shadow-md active:scale-95"
          >
            {loading ? 'Processing...' : 'Generate QR Code'}
          </button>
        </form>

        {qrImage && (
          <div className="px-6 sm:px-12 pb-8 sm:pb-12 flex flex-col items-center animate-in fade-in zoom-in duration-700">
            <div className="p-4 sm:p-6 bg-white rounded-2xl border border-[#e8dfec] shadow-inner">
              <img src={qrImage} alt="QR Code" className="w-40 h-40 sm:w-64 sm:h-64 object-contain" />
            </div>
          </div>
        )}
      </div>
    </main>
  );
}