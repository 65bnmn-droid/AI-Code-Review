import { useState } from "react";

const LANGUAGES = ["JavaScript","TypeScript","Python","Java","Go","Rust","C++","PHP","Ruby","Swift"];

const SYSTEM_PROMPT = (lang) => `You are a senior code reviewer. Analyze the provided ${lang} code and return ONLY valid JSON, no markdown, no preamble.

Return this exact structure:
{
  "issues": [
    {
      "id": "1",
      "severity": "error"|"warning"|"info",
      "line": <number or null>,
      "message": "<concise description of the problem>",
      "fix": "<exact corrected code snippet or line to replace>",
      "fixDescription": "<one sentence explaining the fix>"
    }
  ],
  "fixedCode": "<complete rewritten version of the code with ALL issues fixed>"
}

Focus on: security vulnerabilities, performance issues, bad practices, potential bugs, type safety, error handling. Return 3-8 issues maximum.`;

export default function App() {
  const [code, setCode] = useState("");
  const [lang, setLang] = useState("JavaScript");
  const [loading, setLoading] = useState(false);
  const [issues, setIssues] = useState(null);
  const [fixedCode, setFixedCode] = useState("");
  const [error, setError] = useState("");
  const [banner, setBanner] = useState(false);

  const reviewCode = async () => {
    if (!code.trim()) return;
    setLoading(true);
    setError("");
    setIssues(null);
    setFixedCode("");

    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 1000,
          system: SYSTEM_PROMPT(lang),
          messages: [{ role: "user", content: code }],
        }),
      });

      const data = await res.json();
      const text = data.content.map((b) => b.text || "").join("");
      const clean = text.replace(/```json|```/g, "").trim();
      const parsed = JSON.parse(clean);

      setIssues(parsed.issues || []);
      setFixedCode(parsed.fixedCode || "");
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  const applyAllFixes = () => {
    if (fixedCode) {
      setCode(fixedCode);
      setBanner(true);
      setTimeout(() => setBanner(false), 3000);
    }
  };

  const severityStyle = {
    error: { bg: "#fdeaea", color: "#b93030", border: "#f5a5a5" },
    warning: { bg: "#fdf3dc", color: "#c8820a", border: "#f0c96a" },
    info: { bg: "#e8f0fc", color: "#1a4a8a", border: "#90b4f0" },
  };

  const counts = issues
    ? issues.reduce((acc, i) => ({ ...acc, [i.severity]: (acc[i.severity] || 0) + 1 }), {})
    : {};

  return (
    <div style={{ fontFamily: "'Segoe UI', sans-serif", maxWidth: 1100, margin: "0 auto", padding: 24, background: "#f7f6f2", minHeight: "100vh" }}>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24, paddingBottom: 16, borderBottom: "1px solid #e2e0d8" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 36, height: 36, background: "#0d0d0d", borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ color: "white", fontSize: 18 }}>⌥</span>
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 17 }}>AI Code Review</div>
            <div style={{ fontSize: 11, color: "#6b6860", fontFamily: "monospace" }}>Powered by Claude</div>
          </div>
        </div>
        {issues && issues.length > 0 && (
          <span style={{ background: "#fdf3dc", color: "#c8820a", border: "1px solid #f0c96a", padding: "3px 12px", borderRadius: 20, fontSize: 12, fontWeight: 600, fontFamily: "monospace" }}>
            {issues.length} issues
          </span>
        )}
      </div>

      {/* Main Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* Left: Code Input */}
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: 1, color: "#6b6860", fontFamily: "monospace", textTransform: "uppercase" }}>Source Code</div>
          <textarea
            value={code}
            onChange={(e) => setCode(e.target.value)}
            placeholder="// Paste your code here..."
            style={{ height: 340, fontFamily: "monospace", fontSize: 13, lineHeight: 1.7, background: "#0d0d0d", color: "#e8e4d9", border: "1px solid #333", borderRadius: 8, padding: 14, resize: "none", outline: "none" }}
          />
          <div style={{ display: "flex", gap: 8 }}>
            <select value={lang} onChange={(e) => setLang(e.target.value)} style={{ fontFamily: "inherit", fontSize: 13, fontWeight: 600, background: "white", border: "1px solid #e2e0d8", borderRadius: 6, padding: "8px 12px", outline: "none", cursor: "pointer" }}>
              {LANGUAGES.map((l) => <option key={l}>{l}</option>)}
            </select>
            <button
              onClick={reviewCode}
              disabled={loading || !code.trim()}
              style={{ background: loading ? "#999" : "#0d0d0d", color: "white", border: "none", borderRadius: 6, padding: "8px 20px", fontWeight: 600, fontSize: 13, cursor: loading ? "not-allowed" : "pointer", fontFamily: "inherit" }}
            >
              {loading ? "Reviewing..." : "Review Code ↗"}
            </button>
          </div>
        </div>

        {/* Right: Results */}
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: 1, color: "#6b6860", fontFamily: "monospace", textTransform: "uppercase" }}>Review Results</div>
          <div style={{ height: 340, overflowY: "auto", border: "1px solid #e2e0d8", borderRadius: 8, background: "white" }}>
            {loading && (
              <div style={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
                <div style={{ width: 28, height: 28, border: "2.5px solid #e2e0d8", borderTopColor: "#0d0d0d", borderRadius: "50%", animation: "spin 0.7s linear infinite" }} />
                <div style={{ fontFamily: "monospace", fontSize: 12, color: "#6b6860" }}>Analyzing {lang} code…</div>
                <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
              </div>
            )}
            {!loading && error && (
              <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <span style={{ color: "#b93030", fontSize: 13 }}>Error: {error}</span>
              </div>
            )}
            {!loading && !error && issues === null && (
              <div style={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 8, color: "#6b6860" }}>
                <span style={{ fontSize: 28 }}>⌕</span>
                <span style={{ fontSize: 13 }}>Paste code and click Review</span>
              </div>
            )}
            {!loading && issues && issues.length === 0 && (
              <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <span style={{ color: "#1a6b3c", fontSize: 14, fontWeight: 600 }}>✓ No issues found — looks good!</span>
              </div>
            )}
            {!loading && issues && issues.length > 0 && (
              <>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "8px 14px", borderBottom: "1px solid #e2e0d8", background: "#fafaf8" }}>
                  <span style={{ fontSize: 12, fontWeight: 600, color: "#6b6860", fontFamily: "monospace" }}>{issues.length} ISSUES FOUND</span>
                  <button onClick={applyAllFixes} style={{ background: "#0d0d0d", color: "white", border: "none", borderRadius: 6, padding: "5px 12px", fontWeight: 600, fontSize: 12, cursor: "pointer", fontFamily: "inherit" }}>
                    Apply All Fixes
                  </button>
                </div>
                {issues.map((iss, idx) => {
                  const s = severityStyle[iss.severity] || severityStyle.info;
                  return (
                    <div key={idx} style={{ borderBottom: "1px solid #e2e0d8", padding: "12px 14px", display: "flex", flexDirection: "column", gap: 6 }}>
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                        <span style={{ background: s.bg, color: s.color, border: `1px solid ${s.border}`, padding: "2px 8px", borderRadius: 4, fontFamily: "monospace", fontSize: 10, fontWeight: 600, letterSpacing: 0.5 }}>
                          {iss.severity.toUpperCase()}
                        </span>
                        {iss.line && <span style={{ fontFamily: "monospace", fontSize: 10, color: "#6b6860" }}>Line {iss.line}</span>}
                      </div>
                      <div style={{ fontSize: 12, lineHeight: 1.5 }}>{iss.message}</div>
                      {iss.fix && (
                        <pre style={{ background: "#f8f7f3", borderRadius: 4, padding: "8px 10px", fontFamily: "monospace", fontSize: 11, lineHeight: 1.6, color: "#333", borderLeft: "2px solid #7dd4a0", whiteSpace: "pre-wrap", wordBreak: "break-all", margin: 0 }}>
                          {iss.fix}
                        </pre>
                      )}
                      {iss.fixDescription && <div style={{ fontSize: 11, color: "#6b6860" }}>{iss.fixDescription}</div>}
                    </div>
                  );
                })}
              </>
            )}
          </div>

          {/* Summary chips */}
          {issues && issues.length > 0 && (
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
              {Object.entries(counts).map(([k, v]) => {
                const s = severityStyle[k] || severityStyle.info;
                return (
                  <span key={k} style={{ background: s.bg, color: s.color, border: `1px solid ${s.border}`, padding: "4px 10px", borderRadius: 20, fontSize: 11, fontWeight: 600, fontFamily: "monospace" }}>
                    {v} {k}
                  </span>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Fixed Code */}
      {fixedCode && (
        <div style={{ marginTop: 20, display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: 1, color: "#6b6860", fontFamily: "monospace", textTransform: "uppercase" }}>Fixed Code</div>
          {banner && (
            <div style={{ background: "#e6f7ed", border: "1px solid #7dd4a0", borderRadius: 6, padding: "8px 12px", fontSize: 12, color: "#1a6b3c", fontWeight: 600, textAlign: "center" }}>
              ✓ Fixes applied to editor above
            </div>
          )}
          <pre style={{ background: "#0d0d0d", color: "#a8f0c0", fontFamily: "monospace", fontSize: 12, lineHeight: 1.7, padding: 16, borderRadius: 8, overflow: "auto", maxHeight: 300, border: "1px solid #2a2a2a", margin: 0 }}>
            {fixedCode}
          </pre>
        </div>
      )}
    </div>
  );
}
