import { useState, useEffect } from "react";

// ─── Abstract Bristol Icons (SVG) ───
const BristolIcon = ({ type, size = 28, color = "#7a7a6e" }) => {
  const s = size;
  const c = color;
  switch (type) {
    case 1: // 硬塊 - separated hard lumps
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <circle cx="8" cy="10" r="3.5" fill={c} opacity="0.9" />
          <circle cx="18" cy="8" r="3" fill={c} opacity="0.7" />
          <circle cx="13" cy="17" r="3.2" fill={c} opacity="0.8" />
          <circle cx="21" cy="16" r="2.5" fill={c} opacity="0.6" />
        </svg>
      );
    case 2: // 塊狀 - lumpy sausage
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <rect x="4" y="10" width="20" height="8" rx="4" fill={c} opacity="0.5" />
          <circle cx="9" cy="14" r="2.8" fill={c} opacity="0.8" />
          <circle cx="16" cy="14" r="2.5" fill={c} opacity="0.8" />
          <circle cx="22" cy="14" r="2" fill={c} opacity="0.7" />
        </svg>
      );
    case 3: // 裂紋 - sausage with cracks
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <rect x="3" y="10" width="22" height="8" rx="4" fill={c} opacity="0.7" />
          <line x1="10" y1="10" x2="11" y2="14" stroke="#0e0e0c" strokeWidth="1" opacity="0.5" />
          <line x1="16" y1="10" x2="15" y2="14" stroke="#0e0e0c" strokeWidth="1" opacity="0.5" />
        </svg>
      );
    case 4: // 正常 - smooth sausage
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <rect x="3" y="11" width="22" height="7" rx="3.5" fill={c} opacity="0.8" />
        </svg>
      );
    case 5: // 軟塊 - soft blobs
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <ellipse cx="8" cy="14" rx="5" ry="4" fill={c} opacity="0.6" />
          <ellipse cx="19" cy="13" rx="5.5" ry="4.5" fill={c} opacity="0.55" />
        </svg>
      );
    case 6: // 糊狀 - mushy, ragged
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <path
            d="M4 16 Q6 9, 10 13 Q13 8, 17 12 Q20 9, 24 14 Q22 19, 18 17 Q14 20, 10 17 Q7 19, 4 16Z"
            fill={c}
            opacity="0.5"
          />
        </svg>
      );
    case 7: // 水狀 - liquid drops
      return (
        <svg width={s} height={s} viewBox="0 0 28 28">
          <ellipse cx="14" cy="16" rx="9" ry="5" fill={c} opacity="0.3" />
          <circle cx="10" cy="11" r="1.5" fill={c} opacity="0.6" />
          <circle cx="16" cy="9" r="1.2" fill={c} opacity="0.5" />
          <circle cx="13" cy="14" r="1" fill={c} opacity="0.4" />
        </svg>
      );
    default:
      return null;
  }
};

// ─── Symptom Icons (SVG) ───
const SymptomIcon = ({ type, size = 22, color = "#5a5a50" }) => {
  const s = size;
  const c = color;
  const icons = {
    pain: ( // 腹痛 - radiating pain
      <svg width={s} height={s} viewBox="0 0 22 22">
        <circle cx="11" cy="11" r="4" fill="none" stroke={c} strokeWidth="1.5" />
        <line x1="11" y1="3" x2="11" y2="5.5" stroke={c} strokeWidth="1.2" strokeLinecap="round" />
        <line x1="11" y1="16.5" x2="11" y2="19" stroke={c} strokeWidth="1.2" strokeLinecap="round" />
        <line x1="3" y1="11" x2="5.5" y2="11" stroke={c} strokeWidth="1.2" strokeLinecap="round" />
        <line x1="16.5" y1="11" x2="19" y2="11" stroke={c} strokeWidth="1.2" strokeLinecap="round" />
      </svg>
    ),
    bloat: ( // 腹脹 - expanding circle
      <svg width={s} height={s} viewBox="0 0 22 22">
        <circle cx="11" cy="11" r="5" fill={c} opacity="0.15" />
        <circle cx="11" cy="11" r="5" fill="none" stroke={c} strokeWidth="1.2" strokeDasharray="2 2" />
        <circle cx="11" cy="11" r="3" fill={c} opacity="0.25" />
      </svg>
    ),
    nausea: ( // 噁心 - wave
      <svg width={s} height={s} viewBox="0 0 22 22">
        <path d="M3 11 Q6 6, 9 11 Q12 16, 15 11 Q18 6, 21 11" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" />
        <path d="M3 15 Q6 10, 9 15" fill="none" stroke={c} strokeWidth="1" strokeLinecap="round" opacity="0.4" />
      </svg>
    ),
    fatigue: ( // 疲倦 - drooping line
      <svg width={s} height={s} viewBox="0 0 22 22">
        <path d="M4 8 Q8 8, 11 12 Q14 16, 18 16" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" />
        <circle cx="18" cy="16" r="1.5" fill={c} opacity="0.5" />
      </svg>
    ),
    cramp: ( // 絞痛 - zigzag
      <svg width={s} height={s} viewBox="0 0 22 22">
        <polyline points="4,8 8,15 12,6 16,16 20,9" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
    appetite: ( // 食慾差 - empty bowl
      <svg width={s} height={s} viewBox="0 0 22 22">
        <path d="M4 10 Q4 17, 11 17 Q18 17, 18 10" fill="none" stroke={c} strokeWidth="1.3" strokeLinecap="round" />
        <line x1="8" y1="13" x2="14" y2="13" stroke={c} strokeWidth="1" strokeLinecap="round" opacity="0.3" strokeDasharray="2 2" />
      </svg>
    ),
    joint: ( // 關節痛 - bone joint
      <svg width={s} height={s} viewBox="0 0 22 22">
        <circle cx="11" cy="11" r="2.5" fill="none" stroke={c} strokeWidth="1.3" />
        <line x1="11" y1="4" x2="11" y2="8.5" stroke={c} strokeWidth="1.5" strokeLinecap="round" />
        <line x1="11" y1="13.5" x2="11" y2="18" stroke={c} strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    ),
    fever: ( // 發燒 - thermometer
      <svg width={s} height={s} viewBox="0 0 22 22">
        <rect x="9.5" y="3" width="3" height="12" rx="1.5" fill="none" stroke={c} strokeWidth="1.2" />
        <circle cx="11" cy="17" r="2.5" fill={c} opacity="0.5" />
        <rect x="10.2" y="7" width="1.6" height="6" rx="0.8" fill={c} opacity="0.5" />
      </svg>
    ),
  };
  return icons[type] || null;
};

const ZenGutTracker = () => {
  const [view, setView] = useState("app");
  const [selectedBristol, setSelectedBristol] = useState(null);
  const [symptoms, setSymptoms] = useState({});
  const [bowelCount, setBowelCount] = useState(0);
  const [wellnessScore] = useState(75);
  const [bloodToggle, setBloodToggle] = useState(false);
  const [mucusToggle, setMucusToggle] = useState(false);
  const [severity, setSeverity] = useState({});
  const [mounted, setMounted] = useState(false);
  const [activeTab, setActiveTab] = useState("record");
  const [widgetFlash, setWidgetFlash] = useState(null);

  useEffect(() => {
    setTimeout(() => setMounted(true), 100);
  }, []);

  const bristolTypes = [
    { id: 1, label: "硬塊", desc: "分離的硬塊" },
    { id: 2, label: "塊狀", desc: "香腸狀有塊" },
    { id: 3, label: "裂紋", desc: "有裂紋香腸" },
    { id: 4, label: "正常", desc: "柔軟光滑" },
    { id: 5, label: "軟塊", desc: "柔軟斷塊" },
    { id: 6, label: "糊狀", desc: "蓬鬆糊狀" },
    { id: 7, label: "水狀", desc: "完全液態" },
  ];

  const symptomList = [
    { id: "pain", label: "腹痛" },
    { id: "bloat", label: "腹脹" },
    { id: "nausea", label: "噁心" },
    { id: "fatigue", label: "疲倦" },
    { id: "cramp", label: "絞痛" },
    { id: "appetite", label: "食慾差" },
    { id: "joint", label: "關節痛" },
    { id: "fever", label: "發燒" },
  ];

  const toggleSymptom = (id) => {
    setSymptoms((prev) => {
      const next = { ...prev };
      if (next[id]) {
        delete next[id];
        setSeverity((s) => { const n = { ...s }; delete n[id]; return n; });
      } else {
        next[id] = true;
        setSeverity((s) => ({ ...s, [id]: 1 }));
      }
      return next;
    });
  };

  const getBristolZone = (id) => (id <= 2 ? "hard" : id <= 5 ? "normal" : "soft");
  const zoneColor = (zone) => zone === "hard" ? "#8b6b55" : zone === "normal" ? "#4a7c59" : "#6b7c8b";
  const activeCount = Object.keys(symptoms).length;
  const bristolAvg = selectedBristol || "–";

  const getWellnessGrad = (s) =>
    s >= 70 ? "linear-gradient(135deg,#4a7c59,#6b9e7a)" :
    s >= 40 ? "linear-gradient(135deg,#8b7355,#a89070)" :
    "linear-gradient(135deg,#8b5e5e,#a07070)";

  const widgetRecord = (id) => {
    setSelectedBristol(id);
    setBowelCount((c) => c + 1);
    setWidgetFlash(id);
    setTimeout(() => setWidgetFlash(null), 600);
  };

  // ════════════════════════════════════════
  //  WIDGET
  // ════════════════════════════════════════
  const WidgetView = () => (
    <div style={{ width: 360, margin: "0 auto", padding: "24px 20px" }}>
      <div style={{ textAlign: "center", marginBottom: 20 }}>
        <span style={{ fontSize: 10, letterSpacing: 3, color: "#6a6a5e" }}>WIDGET PREVIEW</span>
      </div>

      {/* ── Medium Widget: Quick Record ── */}
      <div style={{
        background: "linear-gradient(145deg,#1a1a18,#242420,#1e1e1a)",
        borderRadius: 22, padding: "16px 18px", marginBottom: 14,
        border: "1px solid rgba(255,255,255,0.04)",
        boxShadow: "0 8px 32px rgba(0,0,0,0.3)",
      }}>
        {/* Header row */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
          <span style={{ fontSize: 12, color: "#8a8a7a", letterSpacing: 1, fontWeight: 500 }}>GutTracker</span>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <span style={{ fontSize: 11, color: "#6a6a5e" }}>×{bowelCount}</span>
            <div style={{
              background: getWellnessGrad(wellnessScore),
              borderRadius: 10, padding: "2px 8px",
            }}>
              <span style={{ fontSize: 11, color: "#fff", fontWeight: 600 }}>{wellnessScore}</span>
            </div>
          </div>
        </div>

        {/* Bristol quick-tap row */}
        <div style={{ display: "flex", gap: 4, marginBottom: 10 }}>
          {bristolTypes.map((t) => {
            const sel = selectedBristol === t.id;
            const zone = getBristolZone(t.id);
            const flashing = widgetFlash === t.id;
            return (
              <button key={t.id} onClick={() => widgetRecord(t.id)} style={{
                flex: 1, aspectRatio: "1", border: sel ? `1.5px solid ${zoneColor(zone)}` : "1px solid rgba(255,255,255,0.06)",
                borderRadius: 12,
                background: flashing ? `rgba(74,124,89,0.25)` : sel ? `rgba(${zone === "hard" ? "139,107,85" : zone === "normal" ? "74,124,89" : "107,124,139"},0.12)` : "rgba(255,255,255,0.03)",
                cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
                transition: "all 0.3s ease", transform: flashing ? "scale(1.1)" : "scale(1)",
                padding: 0,
              }}>
                <BristolIcon type={t.id} size={22} color={sel ? zoneColor(zone) : "#5a5a50"} />
              </button>
            );
          })}
        </div>

        {/* Active symptoms as tags */}
        {activeCount > 0 && (
          <div style={{ display: "flex", gap: 5, flexWrap: "wrap" }}>
            {Object.keys(symptoms).map((s) => {
              const sym = symptomList.find((x) => x.id === s);
              return (
                <span key={s} style={{
                  fontSize: 10, color: "#a09a8a", background: "rgba(255,255,255,0.05)",
                  padding: "2px 7px", borderRadius: 8, letterSpacing: 0.5,
                }}>{sym?.label}</span>
              );
            })}
          </div>
        )}

        <div style={{ textAlign: "center", marginTop: 8 }}>
          <span style={{ fontSize: 9, color: "#3a3a34", letterSpacing: 1 }}>點擊圖示即可記錄排便</span>
        </div>
      </div>

      {/* ── Small Widgets ── */}
      <div style={{ display: "flex", gap: 12 }}>
        <div style={{
          flex: 1, background: "linear-gradient(145deg,#1a1a18,#222220)", borderRadius: 22,
          padding: 16, border: "1px solid rgba(255,255,255,0.04)",
          boxShadow: "0 4px 20px rgba(0,0,0,0.2)", textAlign: "center",
        }}>
          <div style={{ fontSize: 9, color: "#6a6a5e", letterSpacing: 1.5, marginBottom: 8 }}>排便</div>
          <div style={{ fontSize: 28, fontWeight: 300, color: "#e8e4d8" }}>{bowelCount}</div>
          <div style={{ width: 24, height: 2, background: "#4a7c59", borderRadius: 1, margin: "8px auto 0", opacity: 0.6 }} />
        </div>
        <div style={{
          flex: 1, background: "linear-gradient(145deg,#1a1a18,#222220)", borderRadius: 22,
          padding: 16, border: "1px solid rgba(255,255,255,0.04)",
          boxShadow: "0 4px 20px rgba(0,0,0,0.2)", textAlign: "center",
        }}>
          <div style={{ fontSize: 9, color: "#6a6a5e", letterSpacing: 1.5, marginBottom: 8 }}>健康度</div>
          <div style={{ fontSize: 28, fontWeight: 300, color: "#e8e4d8" }}>{wellnessScore}</div>
          <div style={{ width: 24, height: 2, background: "#4a7c59", borderRadius: 1, margin: "8px auto 0", opacity: 0.6 }} />
        </div>
      </div>
    </div>
  );

  // ════════════════════════════════════════
  //  MAIN APP
  // ════════════════════════════════════════
  return (
    <div style={{
      maxWidth: 400, margin: "0 auto", minHeight: "100vh",
      background: "linear-gradient(180deg,#0e0e0c,#141412 30%,#111110)",
      fontFamily: "'Hiragino Sans','Noto Sans TC',sans-serif", color: "#e8e4d8",
      position: "relative",
    }}>
      {/* Subtle ambient glow */}
      <div style={{
        position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
        backgroundImage: "radial-gradient(ellipse at 50% 0%,rgba(74,124,89,0.03) 0%,transparent 60%)",
        pointerEvents: "none",
      }} />

      <div style={{ position: "relative", zIndex: 1 }}>
        {/* View toggle */}
        <div style={{ display: "flex", justifyContent: "center", padding: "16px 20px 0" }}>
          {["app", "widget"].map((v) => (
            <button key={v} onClick={() => setView(v)} style={{
              background: view === v ? "rgba(255,255,255,0.08)" : "transparent",
              border: "none", color: view === v ? "#e8e4d8" : "#5a5a50",
              fontSize: 11, letterSpacing: 2, padding: "8px 20px", cursor: "pointer",
              borderRadius: v === "app" ? "10px 0 0 10px" : "0 10px 10px 0",
              transition: "all 0.3s ease",
            }}>
              {v.toUpperCase()}
            </button>
          ))}
        </div>

        {view === "widget" ? (
          <div style={{
            opacity: mounted ? 1 : 0, transform: mounted ? "translateY(0)" : "translateY(10px)",
            transition: "all 0.6s cubic-bezier(0.22,1,0.36,1)", paddingTop: 20, paddingBottom: 40,
          }}>
            <WidgetView />
          </div>
        ) : (
          <div style={{ opacity: mounted ? 1 : 0, transition: "opacity 0.6s ease", paddingBottom: 100 }}>

            {/* ── Header ── */}
            <div style={{ padding: "28px 24px 20px", display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <h1 style={{ fontSize: 26, fontWeight: 300, margin: 0, color: "#e8e4d8", letterSpacing: 1 }}>GutTracker</h1>
                <p style={{ fontSize: 11, color: "#6a6a5e", margin: "4px 0 0", letterSpacing: 2 }}>
                  {new Date().toLocaleDateString("zh-TW", { month: "long", day: "numeric", weekday: "short" })}
                </p>
              </div>
              {/* Enso wellness ring */}
              <div style={{ position: "relative", width: 56, height: 56 }}>
                <svg width="56" height="56" viewBox="0 0 56 56">
                  <circle cx="28" cy="28" r="24" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="2" />
                  <circle cx="28" cy="28" r="24" fill="none" stroke="#4a7c59" strokeWidth="2"
                    strokeDasharray={`${(wellnessScore / 100) * 151} 151`} strokeLinecap="round"
                    transform="rotate(-90 28 28)" style={{ transition: "stroke-dasharray 0.8s ease" }} />
                </svg>
                <div style={{
                  position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)",
                  fontSize: 16, fontWeight: 300, color: "#e8e4d8",
                }}>{wellnessScore}</div>
              </div>
            </div>

            {/* ── Daily Summary ── */}
            <div style={{
              display: "flex", gap: 1, margin: "0 20px 24px",
              background: "rgba(255,255,255,0.03)", borderRadius: 16, overflow: "hidden",
            }}>
              {[
                { val: bowelCount, label: "排便", warn: false },
                { val: bristolAvg, label: "Bristol", warn: false },
                { val: activeCount, label: "症狀", warn: activeCount > 0 },
              ].map((item, i) => (
                <div key={i} style={{
                  flex: 1, padding: "14px 0", textAlign: "center",
                  borderRight: i < 2 ? "1px solid rgba(255,255,255,0.04)" : "none",
                }}>
                  <div style={{ fontSize: 22, fontWeight: 300, color: item.warn ? "#c4956a" : "#e8e4d8" }}>{item.val}</div>
                  <div style={{ fontSize: 9, color: "#6a6a5e", letterSpacing: 2, marginTop: 4 }}>{item.label}</div>
                </div>
              ))}
            </div>

            {/* ── Bristol Scale ── */}
            <div style={{ margin: "0 20px 24px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
                <span style={{ fontSize: 12, color: "#8a8a7a", letterSpacing: 2 }}>排便記錄</span>
                <span style={{ fontSize: 10, color: "#4a4a42", letterSpacing: 1 }}>硬 ← → 軟</span>
              </div>

              <div style={{ display: "flex", gap: 6, marginBottom: 10 }}>
                {bristolTypes.map((type) => {
                  const sel = selectedBristol === type.id;
                  const zone = getBristolZone(type.id);
                  const zc = zoneColor(zone);
                  return (
                    <button key={type.id} onClick={() => { setSelectedBristol(type.id); setBowelCount((c) => c + 1); }}
                      style={{
                        flex: 1, aspectRatio: "1", display: "flex", flexDirection: "column",
                        alignItems: "center", justifyContent: "center", gap: 3,
                        border: sel ? `1.5px solid ${zc}` : "1px solid rgba(255,255,255,0.06)",
                        borderRadius: 14, cursor: "pointer", padding: "4px 0",
                        background: sel ? `rgba(${zone === "hard" ? "139,107,85" : zone === "normal" ? "74,124,89" : "107,124,139"},0.12)` : "rgba(255,255,255,0.03)",
                        transition: "all 0.25s ease", transform: sel ? "scale(1.05)" : "scale(1)",
                      }}>
                      <BristolIcon type={type.id} size={24} color={sel ? zc : "#5a5a50"} />
                      <span style={{ fontSize: 9, color: sel ? zc : "#4a4a42", letterSpacing: 0.5 }}>{type.id}</span>
                    </button>
                  );
                })}
              </div>

              {/* Gradient bar */}
              <div style={{
                height: 3, borderRadius: 2, opacity: 0.5, marginBottom: 10,
                background: "linear-gradient(to right,#8b6b55,#8b6b55 28%,#4a7c59 29%,#4a7c59 71%,#6b7c8b 72%,#6b7c8b)",
              }} />

              {selectedBristol && (
                <div style={{
                  textAlign: "center", fontSize: 11, letterSpacing: 1, marginBottom: 12,
                  color: zoneColor(getBristolZone(selectedBristol)),
                }}>
                  {bristolTypes[selectedBristol - 1].desc}
                </div>
              )}

              {/* Blood & Mucus */}
              <div style={{ display: "flex", gap: 8 }}>
                {[
                  { key: "blood", label: "血便", on: bloodToggle, set: setBloodToggle, c: ["180,90,80", "#c47060"] },
                  { key: "mucus", label: "黏液", on: mucusToggle, set: setMucusToggle, c: ["100,140,160", "#7aacbc"] },
                ].map(({ key, label, on, set, c }) => (
                  <button key={key} onClick={() => set(!on)} style={{
                    flex: 1, padding: 10,
                    border: on ? `1px solid rgba(${c[0]},0.4)` : "1px solid rgba(255,255,255,0.06)",
                    borderRadius: 12,
                    background: on ? `rgba(${c[0]},0.1)` : "rgba(255,255,255,0.03)",
                    color: on ? c[1] : "#6a6a5e", fontSize: 12, cursor: "pointer",
                    letterSpacing: 1, transition: "all 0.25s ease",
                  }}>{label}</button>
                ))}
              </div>
            </div>

            {/* Divider */}
            <div style={{ width: 40, height: 1, background: "rgba(255,255,255,0.06)", margin: "0 auto 24px" }} />

            {/* ── Symptoms ── */}
            <div style={{ margin: "0 20px 24px" }}>
              <span style={{ fontSize: 12, color: "#8a8a7a", letterSpacing: 2, display: "block", marginBottom: 16 }}>症狀追蹤</span>

              <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 8 }}>
                {symptomList.map((sym) => {
                  const on = symptoms[sym.id];
                  const level = severity[sym.id] || 1;
                  return (
                    <button key={sym.id} onClick={() => toggleSymptom(sym.id)} style={{
                      padding: "12px 4px 8px", display: "flex", flexDirection: "column",
                      alignItems: "center", gap: 6, cursor: "pointer",
                      border: on ? "1px solid rgba(196,149,106,0.3)" : "1px solid rgba(255,255,255,0.05)",
                      borderRadius: 14, transition: "all 0.25s ease", position: "relative",
                      background: on ? "rgba(196,149,106,0.08)" : "rgba(255,255,255,0.02)",
                    }}>
                      <SymptomIcon type={sym.id} size={22} color={on ? "#c4956a" : "#5a5a50"} />
                      <span style={{ fontSize: 10, color: on ? "#b8a080" : "#5a5a50", letterSpacing: 0.5 }}>{sym.label}</span>
                      {on && (
                        <div style={{ display: "flex", gap: 3, marginTop: 2 }}>
                          {[1, 2, 3].map((dot) => (
                            <div key={dot} onClick={(e) => { e.stopPropagation(); setSeverity((s) => ({ ...s, [sym.id]: dot })); }}
                              style={{
                                width: 5, height: 5, borderRadius: "50%", cursor: "pointer",
                                background: dot <= level ? "#c4956a" : "rgba(255,255,255,0.1)",
                                transition: "background 0.2s ease",
                              }} />
                          ))}
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>
              <div style={{ textAlign: "center", marginTop: 10, fontSize: 9, color: "#3a3a34", letterSpacing: 1 }}>
                點擊啟用 · 點擊圓點調整嚴重度
              </div>
            </div>

            {/* Divider */}
            <div style={{ width: 40, height: 1, background: "rgba(255,255,255,0.06)", margin: "0 auto 24px" }} />

            {/* ── Save Button ── */}
            <div style={{ padding: "0 20px", marginBottom: 24 }}>
              <button style={{
                width: "100%", padding: 14,
                background: "linear-gradient(135deg,#3a6349,#4a7c59)",
                border: "none", borderRadius: 14, color: "#e8e4d8", fontSize: 13,
                letterSpacing: 3, cursor: "pointer", transition: "all 0.3s ease",
                boxShadow: "0 4px 20px rgba(74,124,89,0.15)",
              }}
              onMouseEnter={(e) => { e.target.style.transform = "translateY(-1px)"; e.target.style.boxShadow = "0 6px 24px rgba(74,124,89,0.25)"; }}
              onMouseLeave={(e) => { e.target.style.transform = "translateY(0)"; e.target.style.boxShadow = "0 4px 20px rgba(74,124,89,0.15)"; }}
              >儲存記錄</button>
            </div>

            {/* ── Tab Bar ── */}
            <div style={{
              position: "fixed", bottom: 0, left: "50%", transform: "translateX(-50%)",
              width: "100%", maxWidth: 400, zIndex: 10,
              background: "linear-gradient(180deg,transparent 0%,rgba(14,14,12,0.95) 20%,#0e0e0c 100%)",
              padding: "20px 0 12px",
            }}>
              <div style={{
                display: "flex", margin: "0 20px",
                background: "rgba(255,255,255,0.04)", borderRadius: 16, padding: 4,
              }}>
                {[
                  { id: "record", label: "記錄", icon: "＋" },
                  { id: "calendar", label: "日曆", icon: "☰" },
                  { id: "stats", label: "統計", icon: "▮" },
                  { id: "settings", label: "設定", icon: "⚙" },
                ].map((tab) => (
                  <button key={tab.id} onClick={() => setActiveTab(tab.id)} style={{
                    flex: 1, padding: "10px 0 8px", border: "none", borderRadius: 12,
                    background: activeTab === tab.id ? "rgba(255,255,255,0.08)" : "transparent",
                    cursor: "pointer", display: "flex", flexDirection: "column",
                    alignItems: "center", gap: 3, transition: "all 0.25s ease",
                  }}>
                    <span style={{ fontSize: 15, color: activeTab === tab.id ? "#e8e4d8" : "#4a4a42", transition: "color 0.25s ease" }}>{tab.icon}</span>
                    <span style={{ fontSize: 9, color: activeTab === tab.id ? "#8a8a7a" : "#3a3a34", letterSpacing: 1 }}>{tab.label}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ZenGutTracker;
