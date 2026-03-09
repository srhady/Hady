const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const fs = require('fs');

// বাংলাদেশ সময় জেনারেট করার ফাংশন
const getBDTime = () => {
    const d = new Date();
    const utc = d.getTime() + (d.getTimezoneOffset() * 60000);
    const bdDate = new Date(utc + (3600000 * 6)); // +6 BD time

    let hours = bdDate.getHours();
    let minutes = bdDate.getMinutes();
    let seconds = bdDate.getSeconds();
    let ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12; 
    minutes = minutes < 10 ? '0' + minutes : minutes;
    seconds = seconds < 10 ? '0' + seconds : seconds;
    let strTime = `${hours}:${minutes}:${seconds} ${ampm}`;

    let day = bdDate.getDate();
    let month = bdDate.getMonth() + 1;
    let year = bdDate.getFullYear();
    day = day < 10 ? '0' + day : day;
    month = month < 10 ? '0' + month : month;
    let strDate = `${day}-${month}-${year}`;

    return `${strTime} ${strDate}`;
};

(async () => {
    try {
        console.log("[*] হোমপেজ থেকে লাইভ ম্যাচ খোঁজা হচ্ছে (সুপারফাস্ট Cheerio মোড)...");
        
        const res = await fetch('https://bingstream.info/');
        const html = await res.text();
        const $ = cheerio.load(html);
        
        let liveMatches = [];
        let seen = new Set();

        // আপনার আগের স্ক্রিপ্টের সেই অসাধারন লজিকটি Cheerio তে নিয়ে আসলাম!
        $('a[href*="/live-sport/"]').each((i, el) => {
            let text = $(el).text().trim();
            let href = $(el).attr('href');
            
            // ১. লাইভ হওয়ার কড়া শর্ত
            let isLive = /\bLIVE\b/i.test(text) || /\d+\s*-\s*\d+/.test(text) || /\b(?:Half|Session)\b/i.test(text);
            
            // ২. আপকামিং বাদ দেওয়ার শর্ত
            let isUpcoming = /\b\d{1,2}:\d{2}\b/.test(text);
            
            if (isLive && !isUpcoming) {
                let parts = text.split('\n').map(p => p.trim()).filter(p => p !== '');
                let cleanTitle = "";
                let imageText = "";

                let rev = [...parts].reverse();
                let scoreIdx = rev.findIndex(p => /\d+\s*-\s*\d+/.test(p));

                if (scoreIdx !== -1) {
                    let team2 = rev[scoreIdx - 1] || "";
                    let team1 = rev[scoreIdx + 1] || "";
                    if (team1 && team2) {
                        cleanTitle = `${team1} VS ${team2}`;
                    } else {
                        cleanTitle = rev[scoreIdx].replace(/\s*\d+\s*-\s*\d+\s*/, ' VS ').trim();
                    }
                    imageText = cleanTitle.replace(' VS ', '\nVS\n');
                } else {
                    let rawTitle = rev.find(p => /[a-zA-Z]/.test(p) && !/^(LIVE|NOW|HD|Watch|•)$/i.test(p)) || parts[parts.length - 1];
                    cleanTitle = (rawTitle || "").replace(/\b(LIVE|NOW|HD|Live|live)\b/gi, '').replace(/•/g, '').replace(/ vs /gi, ' VS ').replace(/\s+/g, ' ').trim();
                    imageText = cleanTitle.includes(' VS ') ? cleanTitle.replace(' VS ', '\nVS\n') : cleanTitle;
                }

                // হাবিজাবি মেনু লিংক বাদ দেওয়া
                if (cleanTitle && cleanTitle.length > 5 && !/League|Cup|Menu|Hot|Fixtures|Football|Tennis|Basketball/i.test(cleanTitle)) {
                    if (href && !href.startsWith('http')) href = 'https://bingstream.info' + href;
                    
                    if (!seen.has(href)) {
                        seen.add(href);
                        let encodedTitle = encodeURIComponent(imageText);
                        let imageUrl = `https://placehold.co/800x450/ffffff/000000.png?text=${encodedTitle}&font=Oswald`;
                        liveMatches.push({ title: cleanTitle, url: href, logo: imageUrl });
                    }
                }
            }
        });

        console.log(`[+] মোট ${liveMatches.length} টা লাইভ ম্যাচ/ইভেন্ট পাওয়া গেছে!`);

        if (liveMatches.length === 0) {
            console.log("[-] আপাতত কোনো লাইভ ম্যাচ নেই।");
            process.exit(0);
        }

        let m3uContent = "#EXTM3U\n\n";
        m3uContent += `#"name": "Bingstream Auto Update Playlist",\n`;
        m3uContent += `#"telegram": "https://t.me/livesportsplay",\n`;
        m3uContent += `#"last update time": "${getBDTime()}",\n\n`;

        console.log("\n[*] টোকেন আনলক করার জন্য নিনজা ব্রাউজার চালু হচ্ছে...");
        const browser = await puppeteer.launch({
            headless: "new",
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-gpu'
            ]
        });

        for (let match of liveMatches) {
            console.log(`\n[*] স্ক্যান করছি: ${match.title}`);
            const matchPage = await browser.newPage();
            await matchPage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
            
            await matchPage.setRequestInterception(true);
            
            let bestLink = await new Promise(async (resolve) => {
                let linkFound = false;

                matchPage.on('request', request => {
                    if (request.isInterceptResolutionHandled()) return;
                    
                    const url = request.url();
                    const type = request.resourceType();

                    if (['image', 'stylesheet', 'font'].includes(type)) {
                        return request.abort();
                    }

                    if ((url.includes('.m3u8') || url.includes('.m3u')) && !url.includes('wowhaha.php') && !url.includes('ping.gif')) {
                        if (url.includes('token=') || url.includes('verify=')) {
                            let finalUrl = url.replace(/&amp;/g, '&');
                            if (!linkFound) {
                                linkFound = true;
                                resolve(finalUrl); 
                            }
                        }
                    }
                    request.continue();
                });

                try {
                    await matchPage.goto(match.url, { waitUntil: 'domcontentloaded', timeout: 15000 });
                } catch (e) {}

                setTimeout(async () => {
                    if (!linkFound) {
                        try {
                            const content = await matchPage.content();
                            const frameMatch = content.match(/https?:\/\/api2\.ifnewgen\.xyz\/wowhaha\.php[^\s"'<>]+/);
                            if (frameMatch) {
                                console.log(`  [*] ফ্রেম আনলক করা হচ্ছে...`);
                                const frameUrl = frameMatch[0].replace(/&amp;/g, '&');
                                await matchPage.goto(frameUrl, { waitUntil: 'domcontentloaded', timeout: 10000 }).catch(()=>{});
                                setTimeout(() => resolve(null), 5000);
                            } else {
                                resolve(null);
                            }
                        } catch (e) { resolve(null); }
                    }
                }, 8000); 
            });

            if (bestLink) {
                console.log(`  [+] আসল ভিআইপি লিংক পাওয়া গেছে:\n  ${bestLink}`);
                m3uContent += `#EXTINF:-1 tvg-logo="${match.logo}" group-title="LIVE EVENT", ${match.title}\n`;
                m3uContent += `#EXTVLCOPT:http-user-agent=Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36\n`;
                m3uContent += `#EXTVLCOPT:http-referrer=https://api2.ifnewgen.xyz/\n`;
                m3uContent += `${bestLink}\n\n`;
            } else {
                console.log(`  [-] এই ম্যাচের টোকেন লিংক পাওয়া যায়নি!`);
            }
            
            await matchPage.close();
        }

        await browser.close();

        fs.writeFileSync('playlist.m3u', m3uContent, 'utf-8');
        console.log(`\n[+] সফলভাবে সব লিংক playlist.m3u ফাইলে সেভ করা হয়েছে!`);

    } catch (globalError) {
        console.error("\n❌ স্ক্রিপ্টে একটি এরর ধরা পড়েছে:");
        console.error(globalError);
        process.exit(1);
    }
})();
