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
        
        // ধাপ ১: ব্রাউজার ছাড়াই চোখের পলকে লাইভ ম্যাচ ফিল্টার করা
        const res = await fetch('https://bingstream.info/');
        const html = await res.text();
        const $ = cheerio.load(html);
        
        let liveMatches = [];
        let seen = new Set();

        $('.list-match-sport-live-stream').each((i, el) => {
            if ($(el).find('.isLive').length > 0) {
                let link = $(el).find('a').first().attr('href');
                let name = $(el).find('.txt-name').text().trim();
                
                // টিমের নাম এবং স্কোর থাকলে সুন্দর করে সাজানো
                let team1 = $(el).find('.txt-team-name').first().text().trim();
                let team2 = $(el).find('.txt-team-name').last().text().trim();
                let cleanTitle = name;

                if (team1 && team2) {
                    cleanTitle = `${team1} VS ${team2}`;
                }

                if (link && !link.startsWith('http')) link = 'https://bingstream.info' + link;

                if (link && cleanTitle && !seen.has(link)) {
                    seen.add(link);
                    
                    // প্লেসহোল্ডার লোগো তৈরি
                    let imageText = cleanTitle.replace(' VS ', '\nVS\n');
                    let encodedTitle = encodeURIComponent(imageText);
                    let imageUrl = `https://placehold.co/800x450/ffffff/000000.png?text=${encodedTitle}&font=Oswald`;
                    
                    liveMatches.push({ title: cleanTitle, url: link, logo: imageUrl });
                }
            }
        });

        console.log(`[+] মোট ${liveMatches.length} টা লাইভ ম্যাচ/ইভেন্ট পাওয়া গেছে!`);

        if (liveMatches.length === 0) {
            console.log("[-] আপাতত কোনো লাইভ ম্যাচ নেই।");
            process.exit(0);
        }

        // প্লেলিস্টের বেসিক সেটআপ
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

        // ধাপ ২: প্রতিটি ম্যাচের লিংকে ঢুকে টোকেন ধরা (Promise ব্যবহার করে)
        for (let match of liveMatches) {
            console.log(`\n[*] স্ক্যান করছি: ${match.title}`);
            const matchPage = await browser.newPage();
            await matchPage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
            
            // স্পিড বাড়ানোর জন্য অপ্রয়োজনীয় ফাইল ব্লক করা
            await matchPage.setRequestInterception(true);
            
            let bestLink = await new Promise(async (resolve) => {
                let linkFound = false;

                // নেটওয়ার্ক ট্রাফিক স্ক্যান
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
                                resolve(finalUrl); // লিংক পাওয়া মাত্রই Promise সাকসেস!
                            }
                        }
                    }
                    request.continue();
                });

                try {
                    await matchPage.goto(match.url, { waitUntil: 'domcontentloaded', timeout: 15000 });
                } catch (e) { /* টাইমআউট ইগনোর */ }

                // যদি ডিরেক্ট লিংক না পায়, তবে wowhaha.php ফ্রেম স্ক্যান করবে
                setTimeout(async () => {
                    if (!linkFound) {
                        try {
                            const content = await matchPage.content();
                            const frameMatch = content.match(/https?:\/\/api2\.ifnewgen\.xyz\/wowhaha\.php[^\s"'<>]+/);
                            if (frameMatch) {
                                console.log(`  [*] ফ্রেম আনলক করা হচ্ছে...`);
                                const frameUrl = frameMatch[0].replace(/&amp;/g, '&');
                                await matchPage.goto(frameUrl, { waitUntil: 'domcontentloaded', timeout: 10000 }).catch(()=>{});
                                // ফ্রেমে ঢোকার পর আরও ৫ সেকেন্ড অপেক্ষা করবে
                                setTimeout(() => resolve(null), 5000);
                            } else {
                                resolve(null);
                            }
                        } catch (e) { resolve(null); }
                    }
                }, 8000); // প্রাথমিক ৮ সেকেন্ড ওয়েট
            });

            if (bestLink) {
                console.log(`  [+] আসল ভিআইপি লিংক পাওয়া গেছে:\n  ${bestLink}`);
                m3uContent += `#EXTINF:-1 tvg-logo="${match.logo}" group-title="LIVE EVENT", ${match.title}\n`;
                m3uContent += `#EXTVLCOPT:http-user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64)\n`;
                m3uContent += `#EXTVLCOPT:http-referrer=https://api2.ifnewgen.xyz/\n`;
                m3uContent += `${bestLink}\n\n`;
            } else {
                console.log(`  [-] এই ম্যাচের টোকেন লিংক পাওয়া যায়নি!`);
            }
            
            await matchPage.close();
        }

        await browser.close();

        // ধাপ ৩: প্লেলিস্ট সেভ করা
        fs.writeFileSync('playlist.m3u', m3uContent, 'utf-8');
        console.log(`\n[+] সফলভাবে সব লিংক playlist.m3u ফাইলে সেভ করা হয়েছে!`);

    } catch (globalError) {
        console.error("\n❌ স্ক্রিপ্টে একটি এরর ধরা পড়েছে:");
        console.error(globalError);
        process.exit(1);
    }
})();
