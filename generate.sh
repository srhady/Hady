#!/bin/bash

# ফোল্ডার এবং গিটহাবের র-লিংক
FOLDER_NAME="sky_sports"
GITHUB_RAW_URL="https://raw.githubusercontent.com/srhady/Hady/main/$FOLDER_NAME"

# সাবফোল্ডার তৈরি করা হচ্ছে
mkdir -p "$FOLDER_NAME"

# মেইন প্লেলিস্ট তৈরি শুরু
echo "#EXTM3U x-tvg-url=\"\"" > main.m3u

# সবগুলো চ্যানেলের অরিজিনাল ডেটা
cat << 'EOF' > raw_data.txt
Name: ☰☰☰☰ ┃UK┃ SKY SPORTS HD ☰☰☰☰
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312174&extension=m3u8&play_token=4wZdiDE7ZB
Name: ┃UK┃ SKY SPORTS NEWS HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312175&extension=m3u8&play_token=4UM7NBs3cs
Name: ┃UK┃ SKY SPORTS MAIN EVENT HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312176&extension=m3u8&play_token=veE124Ppo9
Name: ┃UK┃ SKY SPORTS PREMIER LEAGUE HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312177&extension=m3u8&play_token=QrRBjlh00k
Name: ┃UK┃ SKY SPORTS FOOTBALL HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312178&extension=m3u8&play_token=9VxmrnfnrM
Name: ┃UK┃ SKY SPORTS MIX HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312179&extension=m3u8&play_token=aZm9UyO76D
Name: ┃UK┃ SKY SPORTS ACTION / NFL HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312180&extension=m3u8&play_token=g2QWPyZnQB
Name: ┃UK┃ SKY SPORTS F1 HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312181&extension=m3u8&play_token=b9ai42LctO
Name: ┃UK┃ SKY SPORTS RACING HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312182&extension=m3u8&play_token=7L7YPW2iJO
Name: ┃UK┃ SKY SPORTS TENNIS HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312186&extension=m3u8&play_token=w8ocr6Y9FS
Name: ┃UK┃ SKY SPORTS GOLF HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312183&extension=m3u8&play_token=kwBfnRMuNI
Name: ┃UK┃ SKY SPORTS CRICKET HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312184&extension=m3u8&play_token=F4vcMrOrQV
Name: ┃UK┃ SKY SPORTS+ HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312185&extension=m3u8&play_token=we70N6QUbE
Name: ┃UK┃ RACING TV UK HD
Link: ffmpeg http://line.tvdsz.cc:80/play/live.php?mac=00:1A:79:B5:AD:FB&stream=1312829&extension=m3u8&play_token=iHHgoOyIpr
EOF

# ডাটা প্রসেসিং শুরু
grep -E "^Name:|^Link:" raw_data.txt | paste - - | while read -r name_line link_line; do
    
    # নাম এবং ক্লিন নাম বের করা
    original_name=$(echo "$name_line" | sed 's/Name: //g')
    clean_name=$(echo "$original_name" | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    file_name=$(echo "$clean_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_').m3u8
    
    # লিংক ক্লিন করা
    raw_url=$(echo "$link_line" | sed 's/Link: //g' | sed 's/ffmpeg //g' | sed 's/&play_token=.*//g')
    
    # ডামি টিভিজি লোগো তৈরি
    logo_text=$(echo "$clean_name" | sed 's/ /+/g')
    tvg_logo="https://ui-avatars.com/api/?name=${logo_text}&background=0D8ABC&color=fff&size=200"
    
    # সাবফোল্ডারে 4 লাইনের m3u8 ফাইল তৈরি
    cat << INLINE_EOF > "$FOLDER_NAME/$file_name"
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=4000000,RESOLUTION=1920x1080
$raw_url
INLINE_EOF

    # মেইন প্লেলিস্টে ডাটা যুক্ত করা
    echo "#EXTINF:-1 tvg-id=\"\" tvg-logo=\"$tvg_logo\" group-title=\"UK SKY SPORTS\", $original_name" >> main.m3u
    echo "$GITHUB_RAW_URL/$file_name" >> main.m3u

done

# টেম্পোরারি ফাইল মুছে ফেলা
rm raw_data.txt
