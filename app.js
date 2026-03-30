document.addEventListener("DOMContentLoaded", async () => {
    const urlParams = new URLSearchParams(window.location.search);
    const matchTitle = urlParams.get('match'); 
    const currentUrl = window.location.href;
    
    // সোশ্যাল মিডিয়া শেয়ার লিংক
    const encodedUrl = encodeURIComponent(currentUrl);
    document.getElementById('share-fb').href = `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`;
    document.getElementById('share-wa').href = `https://api.whatsapp.com/send?text=Watch Live: ${encodedUrl}`;
    document.getElementById('share-tg').href = `https://telegram.me/share/url?url=${encodedUrl}`;

    if (!matchTitle) {
        document.getElementById('match-title').innerText = "কোনো ম্যাচ সিলেক্ট করা হয়নি!";
        return;
    }

    try {
        // আপনার আসল JSON ফাইলের লিংক
        const jsonUrl = 'https://raw.githubusercontent.com/srhady/data/refs/heads/main/live_sports_playlist.json';
        const response = await fetch(jsonUrl); 
        const data = await response.json();

        // ১ম পেজে যে ম্যাচে ক্লিক করা হয়েছে, সেটি খুঁজে বের করা
        const matchData = data.find(m => m["Match Title"] === matchTitle);

        if (matchData) {
            document.getElementById('match-title').innerText = matchData["Match Title"];
            document.getElementById('league-name').innerText = matchData["League"];
            
            if(matchData["Team 1 Logo"]) document.getElementById('team1-logo').src = matchData["Team 1 Logo"];
            if(matchData["Team 2 Logo"]) document.getElementById('team2-logo').src = matchData["Team 2 Logo"];

            // ভিডিও প্লেয়ার এবং সার্ভার বাটন সেট করা
            const serverContainer = document.getElementById('server-buttons');
            
            // আপনার JSON ফাইলে যদি ভিডিও লিংকের নাম "Live Link" বা "Link 1" থাকে, তবে নিচের কোড কাজ করবে
            // যদি আপনার JSON এ লিংকের নাম অন্য কিছু হয় (যেমন "URL" বা "Stream"), তাহলে নিচের "Live Link" লেখাটি চেঞ্জ করতে হবে
            
            let streamUrl = matchData["Live Link"] || matchData["Link 1"] || matchData["url"]; 

            if (streamUrl) {
                const btn = document.createElement('button');
                btn.className = 'server-btn';
                btn.innerText = "▶ Server 1 (HD)";
                btn.onclick = () => { document.getElementById('video-frame').src = streamUrl; };
                serverContainer.appendChild(btn);
                
                // অটোমেটিক প্লেয়ারে ভিডিও লোড করা
                document.getElementById('video-frame').src = streamUrl;
            } else {
                serverContainer.innerHTML = "<p style='color:red;'>No stream link found in JSON.</p>";
            }

        } else {
            document.getElementById('match-title').innerText = "ম্যাচটি পাওয়া যায়নি বা শেষ হয়ে গেছে।";
        }
    } catch (error) {
        console.error("ডেটা লোড করতে সমস্যা হচ্ছে:", error);
    }
});