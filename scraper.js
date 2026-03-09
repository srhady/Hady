const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const fs = require('fs');

async function generatePlaylist() {
    try {
        console.log("[*] হোমপেজ থেকে লাইভ ম্যাচ খোঁজা হচ্ছে (সুপারফাস্ট মোড)...");
        const res = await fetch('https://bingstream.info/');
        const html = await res.text();
        const $ = cheerio.load(html);
        let matches = [];

        $('.list-match-sport-live-stream').each((i, el) => {
            if($(el).find('.isLive').length > 0) {
                let link = $(el).find('a').first().attr('href');
                let name = $(el).find('.txt-name').text().trim();
                
                if(link && !link.startsWith('http')) link = 'https://bingstream.info' + link;
                if(link && name && !matches.find(m => m.name === name)) matches.push({name, link});
            }
        });

        console.log(`[+] মোট ${matches.length} টা লাইভ ম্যাচ পাওয়া গেছে!`);
        if (matches.length === 0) return console.log("[-] আপাতত কোনো লাইভ ম্যাচ নেই।");

        console.log("\n[*] নিনজা ব্রাউজার চালু হচ্ছে...");
        const browser = await puppeteer.launch({
            headless: "new",
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
        });

        let playlistContent = "#EXTM3U\n";

        for (let match of matches) {
            console.log(`\n[*] স্ক্যান করছি: ${match.name}`);
            const page = await browser.newPage();
            
            // স্পিড বাড়ানোর জন্য ব্রাউজারের ছবি, CSS ও অ্যাড ব্লক করা
            await page.setRequestInterception(true);
            page.on('request', (req) => {
                const type = req.resourceType();
                if (['image', 'stylesheet', 'font', 'media'].includes(type)) {
                    req.abort();
                } else {
                    req.continue();
                }
            });

            // টোকেন লিংক ধরার ফাঁদ (Promise)
            let tokenLink = await new Promise(async (resolve) => {
                let isResolved = false;

                // নেটওয়ার্কের প্রতিটি রিকোয়েস্টে নজর রাখা
                page.on('request', req => {
                    const url = req.url();
                    // যদি লিংকে m3u8, token এবং x-sign তিনটাই থাকে, তবে ধরে ফেলো!
                    if (url.includes('.m3u8') && url.includes('token=') && url.includes('x-sign=')) {
                        if (!isResolved) {
                            isResolved = true;
                            resolve(url);
                        }
                    }
                });

                try {
                    // পেজ ওপেন করার কমান্ড দেওয়া হলো
                    await page.goto(match.link, { waitUntil: 'domcontentloaded', timeout: 15000 });
                } catch (e) {
                    // পেজ লোড হতে টাইমআউট হলেও সমস্যা নেই, আমরা লিংক পেয়ে গেলে আগেই বেরিয়ে আসব
                }

                // ১৫ সেকেন্ডের মধ্যে না পেলে হাল ছেড়ে দেওয়া
                setTimeout(() => { if(!isResolved) resolve(null); }, 15000);
            });

            if (tokenLink) {
                // এই লাইনের জন্যই আপনি গিটহাব অ্যাকশনস-এর লগে সরাসরি লিংক দেখতে পাবেন!
                console.log(`  [+] আসল ভিআইপি লিংক পাওয়া গেছে:\n  ${tokenLink}`);
                
                // Referer হেডারটি যুক্ত করে প্লেলিস্টে সেভ করা
                playlistContent += `#EXTINF:-1, ${match.name}\n#EXTVLCOPT:http-referrer=https://api2.ifnewgen.xyz/\n${tokenLink}\n`;
            } else {
                console.log(`  [-] এই ম্যাচের টোকেন লিংক পাওয়া যায়নি! সার্ভার হয়তো ব্লক করেছে।`);
            }
            
            await page.close();
        }

        await browser.close();
        fs.writeFileSync('playlist.m3u', playlistContent);
        console.log("\n[+] সফলভাবে playlist.m3u ফাইলে সব লিংক সেভ করা হয়েছে!");

    } catch (error) {
        console.error("কোড রান করতে এরর:", error);
    }
}

generatePlaylist();
