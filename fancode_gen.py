import requests
import json

# --- কনফিগারেশন ---
SOURCE_JSON_URL = "https://raw.githubusercontent.com/drmlive/fancode-live-events/refs/heads/main/fancode.json"
OUTPUT_PLAYLIST = "fancode_bd.m3u"  # এই নামে প্লেলিস্ট তৈরি হবে
# ------------------

def generate_playlist():
    print("Fetching JSON data...")
    try:
        response = requests.get(SOURCE_JSON_URL)
        response.raise_for_status()
        events = response.json() # JSON ডাটা লোড করা হচ্ছে

        # M3U ফাইলের হেডার
        m3u_content = "#EXTM3U x-tvg-url=\"https://avigenz.live/epg.xml\"\n"

        count = 0
        for event in events:
            # JSON থেকে প্রয়োজনীয় তথ্য নেওয়া (কী-গুলো চেক করে নেওয়া হচ্ছে)
            # সাধারণত এই ধরনের JSON-এ 'event_name', 'video_url', 'event_category' থাকে
            title = event.get('event_name', 'Unknown Event')
            category = event.get('event_category', 'Sports')
            src_url = event.get('video_url', '') or event.get('url', '')

            if src_url:
                # --- আসল কাজ: লিংক পরিবর্তন ---
                # https://in- দিয়ে শুরু হলে সেটা https://bd- করা হবে
                new_url = src_url.replace("https://in-", "https://bd-")

                # প্লেলিস্ট ফরম্যাটে সাজানো
                m3u_content += f'\n#EXTINF:-1 group-title="{category}" tvg-id="" tvg-logo="https://fancode.com/skillup-uploads/prod-images/2022/11/fancode.png", {title}\n'
                m3u_content += f'{new_url}\n'
                count += 1

        # ফাইল সেভ করা
        with open(OUTPUT_PLAYLIST, "w", encoding="utf-8") as f:
            f.write(m3u_content)

        print(f"Success! Generated playlist with {count} channels.")
        print(f"Saved as: {OUTPUT_PLAYLIST}")

    except Exception as e:
        print(f"Error occurred: {e}")

if __name__ == "__main__":
    generate_playlist()
