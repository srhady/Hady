import requests
import json
import os
import sys

# --- কনফিগারেশন ---
# সঠিক Raw লিংক ব্যবহার করা হয়েছে (refs/heads বাদ দেওয়া হয়েছে)
SOURCE_JSON_URL = "https://raw.githubusercontent.com/drmlive/fancode-live-events/main/fancode.json"
OUTPUT_PLAYLIST = "fancode_bd.m3u"
# ------------------

def generate_playlist():
    print(f"Fetching data from: {SOURCE_JSON_URL}")
    
    try:
        response = requests.get(SOURCE_JSON_URL, timeout=15)
        response.raise_for_status() # লিংক ভুল হলে বা কাজ না করলে এখানেই থামবে
        
        try:
            events = response.json()
        except json.JSONDecodeError:
            print("Error: The downloaded data is not valid JSON.")
            sys.exit(1)

        print(f"Found {len(events)} events. Processing...")

        m3u_content = '#EXTM3U x-tvg-url="https://avigenz.live/epg.xml"\n'
        
        count = 0
        for event in events:
            title = event.get('event_name', 'Unknown Event')
            category = event.get('event_category', 'Sports')
            src_url = event.get('video_url', '') or event.get('url', '')

            # যদি ভিডিও লিংক থাকে তবেই প্রসেস করবে
            if src_url:
                # লিংক পরিবর্তন লজিক
                new_url = src_url.replace("https://in-", "https://bd-")
                
                m3u_content += f'\n#EXTINF:-1 group-title="{category}" tvg-id="" tvg-logo="https://fancode.com/skillup-uploads/prod-images/2022/11/fancode.png", {title}\n'
                m3u_content += f'{new_url}\n'
                count += 1

        # ফাইল সেভ করা (ডাটা থাকুক বা না থাকুক, ফাইল তৈরি হবেই)
        with open(OUTPUT_PLAYLIST, "w", encoding="utf-8") as f:
            f.write(m3u_content)

        print(f"Success! Generated playlist with {count} channels.")
        print(f"Saved as: {OUTPUT_PLAYLIST}")

    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        # ফাইল তৈরি না হলে গিটহাব অ্যাকশন যাতে ফেইল করে, সেজন্য exit code 1 দেওয়া হলো
        sys.exit(1)

if __name__ == "__main__":
    generate_playlist()
