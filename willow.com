<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WILLOW LIVE - Match Center</title>
  
  <!-- Tailwind CSS -->
  <script src="https://cdn.tailwindcss.com"></script>
  <!-- FontAwesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
  <!-- Google Fonts: Inter -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  
  <!-- JW Player Scripts -->
  <script src='https://cdn.jwplayer.com/libraries/MAaRkUjT.js'></script>
  <script>jwplayer.key="jTL7dlu7ybUI5NZnDdVgb1laM8/Hj3ftIJ5Vqg==";</script>

  <style>
    body { 
      font-family: 'Inter', sans-serif; 
      background-color: #f1f5f9; 
      color: #1e293b; 
    }
    
    .no-scrollbar::-webkit-scrollbar { display: none; }
    
    .pulse-dot {
      animation: pulse-ring 1.5s cubic-bezier(0.215, 0.61, 0.355, 1) infinite;
    }
    
    @keyframes pulse-ring {
      0% { transform: scale(0.8); box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
      70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
      100% { transform: scale(0.8); box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
    }

    .match-card {
      transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
    }
    .match-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.1);
      border-color: #cbd5e1;
    }

    /* Light Theme Player Modal */
    .player-modal-backdrop { 
      display: none; 
      position: fixed; 
      inset: 0; 
      background: rgba(255, 255, 255, 0.85); 
      backdrop-filter: blur(5px);
      z-index: 9999; 
      align-items: center; 
      justify-content: center; 
    }
    
    .player-modal-content {
      background: #ffffff;
      border: 1px solid #e2e8f0;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      border-radius: 16px;
      width: 100%;
      max-width: 1000px;
      max-height: 95vh;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
    }
  </style>
</head>
<body class="pb-16 antialiased">

  <!-- Centered Navigation -->
  <nav class="bg-white border-b border-slate-200 sticky top-0 z-50 shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-center h-16 items-center">
        <!-- Brand -->
        <div class="flex items-center gap-2">
          <div class="bg-emerald-600 text-white w-8 h-8 rounded flex items-center justify-center font-bold text-lg">W</div>
          <span class="font-extrabold text-xl tracking-tight text-slate-800">WILLOW LIVE</span>
        </div>
      </div>
    </div>
  </nav>

  <!-- Main Content Area -->
  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8">
    
    <!-- Search & Filter Area -->
    <div class="flex flex-col md:flex-row gap-4 mb-8">
      <div class="relative flex-grow">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <i class="fas fa-search text-slate-400"></i>
        </div>
        <input type="text" id="searchInput" class="block w-full pl-10 pr-3 py-3 border border-slate-200 rounded-xl leading-5 bg-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 sm:text-sm transition-shadow font-medium shadow-sm" placeholder="Search matches, series, or teams...">
      </div>
      
      <div class="flex gap-2 overflow-x-auto no-scrollbar" id="filterContainer">
        <!-- Active Filter Button Style -->
        <button data-filter="ALL" class="filter-btn shrink-0 bg-slate-800 text-white border border-slate-800 px-5 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-colors shadow-sm">All Matches</button>
        <!-- Inactive Filter Button Style -->
        <button data-filter="LIVE" class="filter-btn shrink-0 bg-white text-slate-600 border border-slate-200 hover:bg-slate-50 px-5 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-colors shadow-sm">Live Now</button>
        <!-- Inactive Filter Button Style -->
        <button data-filter="UPCOMING" class="filter-btn shrink-0 bg-white text-slate-600 border border-slate-200 hover:bg-slate-50 px-5 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-colors shadow-sm">Upcoming</button>
      </div>
    </div>

    <!-- Match Grid -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5" id="matchesGrid">
      <!-- Loader -->
      <div class="col-span-full py-16 flex flex-col items-center justify-center text-slate-400">
        <i class="fas fa-circle-notch fa-spin text-4xl mb-4 text-emerald-500"></i>
        <p class="font-semibold">Loading Events...</p>
      </div>
    </div>
  </main>

  <!-- Player Modal -->
  <div id="playerModal" class="player-modal-backdrop">
    <div class="player-modal-content p-1 md:p-4 m-4">
      
      <!-- Modal Header -->
      <div class="flex justify-between items-center px-4 py-3 border-b border-slate-100">
        <h2 id="modalTitle" class="text-sm md:text-base font-bold text-slate-800 line-clamp-1 pr-4">Match Title</h2>
        <button onclick="closePlayer()" class="text-slate-400 hover:text-red-500 transition-colors rounded-full p-1 focus:outline-none bg-slate-100 hover:bg-red-50">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
        </button>
      </div>
      
      <!-- Video Player Container -->
      <div class="w-full bg-black aspect-video rounded-lg overflow-hidden my-4 shadow-inner">
        <div id="jwplayer_div" class="w-full h-full"></div>
      </div>
      
      <!-- Server Selection -->
      <div class="px-4 pb-4">
        <h3 class="text-[11px] font-bold text-slate-500 uppercase tracking-widest mb-3"><i class="fas fa-server mr-1"></i> Available Sources</h3>
        <div id="serverList" class="flex flex-wrap gap-2">
          <!-- Server Buttons injected dynamically -->
        </div>
      </div>
      
    </div>
  </div>

  <script>
    // Config
    const JSON_URL = "https://raw.githubusercontent.com/srhady/willow-event/refs/heads/main/live_sports.json";
    
    // State
    let allMatches = [];
    let currentFilter = "ALL";
    let searchQuery = "";
    
    // UI Refs
    const matchesGrid = document.getElementById("matchesGrid");
    const searchInput = document.getElementById("searchInput");
    const filterBtns = document.querySelectorAll(".filter-btn");

    // Fetch JSON Data
    async function fetchSportsData() {
      try {
        const res = await fetch(JSON_URL, { cache: "no-store" });
        if (!res.ok) throw new Error("Failed to fetch feed");
        const data = await res.json();
        
        allMatches = data.Matches || [];
        renderMatches();
      } catch (error) {
        console.error("Data Load Error:", error);
        matchesGrid.innerHTML = `
          <div class="col-span-full bg-red-50 border border-red-100 text-red-600 p-8 rounded-xl text-center">
            <i class="fas fa-exclamation-circle text-3xl mb-2"></i><br>
            <span class="font-bold">Error loading match feed.</span>
          </div>`;
      }
    }

    // Render Cards
    function renderMatches() {
      let filtered = allMatches.filter(match => {
        const mStatus = (match.status || "").toUpperCase();
        const statusMatch = currentFilter === "ALL" || mStatus === currentFilter;
        const searchTarget = `${match.title} ${match.synopsis}`.toLowerCase();
        const searchMatch = searchTarget.includes(searchQuery.toLowerCase());
        return statusMatch && searchMatch;
      });

      // Sort LIVE first
      filtered.sort((a, b) => {
        const sA = (a.status || "").toUpperCase() === "LIVE" ? 0 : 1;
        const sB = (b.status || "").toUpperCase() === "LIVE" ? 0 : 1;
        return sA - sB;
      });

      if (filtered.length === 0) {
        matchesGrid.innerHTML = `
          <div class="col-span-full py-12 text-center text-slate-400">
            <i class="fas fa-calendar-times text-4xl mb-3"></i><br>
            <span class="font-medium">No matches available.</span>
          </div>`;
        return;
      }

      matchesGrid.innerHTML = filtered.map(match => {
        const isLive = (match.status || "").toUpperCase() === "LIVE";
        const coverImg = match.cover_image || "https://via.placeholder.com/600x338/e2e8f0/64748b?text=NO+IMAGE";
        const timeStr = match.time || "TBA";
        
        // Smart parse to get tournament name if separated by hyphen
        let series = "Cricket Match";
        let mainTitle = match.title;
        if(match.title.includes(' - ')) {
          const parts = match.title.split(' - ');
          series = parts[0].trim();
          mainTitle = parts.slice(1).join(' - ').trim();
        }

        return `
          <div class="match-card bg-white rounded-2xl border border-slate-200 overflow-hidden flex flex-col h-full shadow-sm">
            <!-- Image Header (Aspect-video ensures the whole photo is visible) -->
            <div class="relative w-full aspect-video bg-slate-100 overflow-hidden">
              <img src="${coverImg}" class="w-full h-full object-cover" loading="lazy" onerror="this.src='https://via.placeholder.com/600x338/e2e8f0/64748b?text=IMAGE+ERROR'">
              <div class="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent"></div>
              
              <div class="absolute top-2 left-2">
                ${isLive 
                  ? `<span class="bg-red-500 text-white text-[9px] font-bold px-2 py-1 rounded-md flex items-center shadow-sm uppercase tracking-wider"><span class="w-1.5 h-1.5 bg-white rounded-full mr-1.5 pulse-dot"></span> LIVE</span>` 
                  : `<span class="bg-amber-400 text-slate-900 text-[9px] font-bold px-2 py-1 rounded-md flex items-center shadow-sm uppercase tracking-wider"><i class="far fa-clock mr-1.5"></i> UPCOMING</span>`
                }
              </div>
            </div>
            
            <!-- Compact Content Box -->
            <div class="p-3 flex flex-col flex-grow">
              <div class="text-[9px] font-bold text-emerald-600 uppercase tracking-widest mb-1 line-clamp-1">${series}</div>
              <h3 class="font-bold text-slate-800 text-xs leading-snug mb-2 line-clamp-2">${mainTitle}</h3>
              
              <div class="mt-auto pt-2 border-t border-slate-100 flex items-center justify-between">
                <div class="text-[10px] font-semibold text-slate-500 flex items-center gap-1.5">
                  <i class="far fa-calendar text-slate-400"></i> ${timeStr}
                </div>
              </div>
              
              <!-- Action Button -->
              <button onclick="openPlayer('${match.match_id}')" class="mt-2 w-full py-2 rounded-lg text-[11px] font-bold transition-colors ${
                isLive 
                ? 'bg-slate-800 hover:bg-slate-700 text-white' 
                : 'bg-slate-100 hover:bg-slate-200 text-slate-600'
              }">
                ${isLive ? 'WATCH LIVE' : 'VIEW INFO'}
              </button>
            </div>
          </div>
        `;
      }).join('');
    }

    // Search Interaction
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value;
      renderMatches();
    });

    // Filter Buttons Interaction
    filterBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        // Reset all buttons to inactive styling
        filterBtns.forEach(b => {
          b.className = "filter-btn shrink-0 bg-white text-slate-600 border border-slate-200 hover:bg-slate-50 px-5 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-colors shadow-sm";
        });
        
        // Apply active styling to clicked button
        btn.className = "filter-btn shrink-0 bg-slate-800 text-white border border-slate-800 px-5 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-colors shadow-sm";
        
        currentFilter = btn.getAttribute('data-filter');
        renderMatches();
      });
    });

    // ==========================================
    // Player Modal & JW Player Logic
    // ==========================================
    let currentStreams = [];
    let currentDrmKey = "";

    function openPlayer(matchId) {
      const match = allMatches.find(m => m.match_id === matchId);
      if(!match) return;

      document.getElementById('modalTitle').innerText = match.title;
      
      // Collect streams
      currentStreams = [];
      if(match.stream_url_alpha) {
        for(const [name, url] of Object.entries(match.stream_url_alpha)) {
          if(url) currentStreams.push({ group: "Feed A", name: name, url: url });
        }
      }
      if(match.stream_url_bravo) {
        for(const [name, url] of Object.entries(match.stream_url_bravo)) {
          if(url) currentStreams.push({ group: "Feed B", name: name, url: url });
        }
      }

      currentDrmKey = match.drm_key || "";

      // Open Modal
      const modal = document.getElementById('playerModal');
      modal.style.display = 'flex';
      document.body.style.overflow = 'hidden';

      buildServerList();
      
      // Auto Play first stream
      if(currentStreams.length > 0) {
        startVideo(currentStreams[0].url, currentDrmKey, 0);
      } else {
        document.getElementById('jwplayer_div').innerHTML = `
          <div class="w-full h-full flex flex-col items-center justify-center text-slate-400 bg-slate-900 font-medium text-sm">
            <i class="fas fa-video-slash text-2xl mb-2 text-slate-600"></i>
            No valid stream sources available.
          </div>
        `;
      }
    }

    function buildServerList(activeIndex = 0) {
      const container = document.getElementById('serverList');
      if(currentStreams.length === 0) {
        container.innerHTML = '<span class="text-slate-400 text-xs">No servers available.</span>';
        return;
      }
      
      container.innerHTML = currentStreams.map((stream, idx) => `
        <button onclick="startVideo('${stream.url}', '${currentDrmKey}', ${idx})" 
          class="px-3 py-1.5 rounded-md text-[10px] font-bold transition-colors border ${
            idx === activeIndex 
            ? 'bg-emerald-600 text-white border-emerald-600 shadow-sm' 
            : 'bg-slate-50 text-slate-600 border-slate-200 hover:border-emerald-300 hover:text-emerald-600'
          }">
          ${stream.group} - ${stream.name}
        </button>
      `).join('');
    }

    function startVideo(url, drmKeyStr, index) {
      buildServerList(index);
      
      let config = {
        file: url,
        width: "100%",
        height: "100%",
        autostart: true,
        stretching: "uniform",
        cast: {}
      };

      if(drmKeyStr && drmKeyStr.includes(':')) {
        const parts = drmKeyStr.split(':');
        if(parts.length === 2) {
          config.type = "dash";
          config.drm = {
            clearkey: { keyId: parts[0].trim(), key: parts[1].trim() }
          };
        }
      }

      jwplayer("jwplayer_div").setup(config);
    }

    function closePlayer() {
      try {
        if (jwplayer("jwplayer_div").getState() !== "idle") {
           jwplayer("jwplayer_div").remove(); 
        }
      } catch(e) {}
      
      document.getElementById('playerModal').style.display = 'none';
      document.body.style.overflow = 'auto';
    }

    // Init Data Fetch
    fetchSportsData();
  </script>
</body>
</html>
