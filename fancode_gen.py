import requests
import json
import sys

# --- কনফিগারেশন ---
SOURCE_JSON_URL = "https://raw.githubusercontent.com/drmlive/fancode-live-events/main/fancode.json"
OUTPUT_PLAYLIST = "fancode_bd.m3u"
# ------------------

def generate_playlist():
    print(f"Fetching data from: {SOURCE_JSON_URL}")
    
    try:
        response = requests.get(SOURCE_JSON_URL, timeout=15)
        response.raise_for_status()
        
        try:
            data = response.json()
        except json.JSONDecodeError:
            print("Error: Invalid JSON format.")
            sys.exit(1)

        # --- ফিক্স: ডাটা ফরম্যাট চেক করা হচ্ছে ---
        events = []
        if isinstance(data, dict):
            # যদি ডিকশনারি হয় (যেমন: {"id1": {...}, "id2": {...}})
            # তাহলে আমরা values() নেব
            print("Detected JSON as Dictionary. Extracting values...")
            events = list(data.values())
        elif isinstance(data, list):
            # যদি সরাসরি লিস্ট হয়
            events = data
        else:
            print("Error: Unknown JSON structure.")
            sys.exit(1)

        print(f"Found {len(events)} events. Processing...")

        m3u_content = '#EXTM3U x-tvg-url="https://avigenz.live/epg.xml"\n'
        
        count = 0
        for event in events:
            # যদি ইভেন্টটি স্ট্রিং হয় (ভুলবশত), সেটা স্কিপ করবে
            if isinstance(event, str):
                continue
                
            title = event.get('event_name', 'Unknown Event')
            category = event.get('event_category', 'Sports')
            src_url = event.get('video_url', '') or event.get('url', '')

            if src_url:
                # লিংক পরিবর্তন: in-mc-fdlive -> bd-mc-fdlive
                # এবং ফাইল এক্সটেনশন যদি .m3u8 না থাকে, যোগ করার লজিক (অপশনাল)
                new_url = src_url.replace("https://in-", "https://bd-")
                
                m3u_content += f'\n#EXTINF:-1 group-title="{category}" tvg-id="" tvg-logo="https://fancode.com/skillup-uploads/prod-images/2022/11/fancode.png", {title}\n'
                m3u_content += f'{new_url}\n'
                count += 1

        # ফাইল সেভ করা
        with open(OUTPUT_PLAYLIST, "w", encoding="utf-8") as f:
            f.write(m3u_content)

        print(f"Success! Generated playlist with {count} channels.")
        
    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    generate_playlist()

