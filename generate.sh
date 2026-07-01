#!/bin/bash

# ফোল্ডার এবং গিটহাবের র-লিংক
FOLDER_NAME="sky_sports"
GITHUB_RAW_URL="https://raw.githubusercontent.com/srhady/Hady/main/$FOLDER_NAME"

# সাবফোল্ডার তৈরি করা হচ্ছে
mkdir -p "$FOLDER_NAME"

# মেইন প্লেলিস্ট তৈরি শুরু (প্রথম লাইনে শুধু #EXTM3U থাকবে)
echo "#EXTM3U" > sky-sports.m3u

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
while read -r line; do
    if [[ "$line" == Name:* ]]; then
        original_name="${line#Name: }"
        
        # tvg-name এর আগে থেকে UK এবং সব চিহ্ণ বাদ দিয়ে সরাসরি ফ্রেশ নাম নেওয়া হচ্ছে
        clean_name=$(echo "$original_name" | sed 's/☰//g' | sed 's/┃UK┃ //g' | sed 's/┃//g' | tr -s ' ' | sed 's/^ *//;s/ *$//')
        
        # সাবফোল্ডারের ফাইলের নামের জন্য স্পেশাল ক্যারেক্টার বাদ দেওয়া হচ্ছে
        file_name=$(echo "$clean_name" | sed 's/[^a-zA-Z0-9 ]//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '_').m3u8
        
        # আপনার দেওয়া লোগো লিংকগুলো সুনির্দিষ্টভাবে সেট করা হচ্ছে
        case "$clean_name" in
            *"NEWS"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/c/cc/Sky_Sport_News_2020.svg/revision/latest/scale-to-width-down/284?cb=20201029124150" ;;
            *"MAIN EVENT"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/d/d7/Sky_Sports_Main_Event_Stacked.svg/revision/latest/scale-to-width-down/250?cb=20220728001048" ;;
            *"PREMIER LEAGUE"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/3/3e/Sky_Sports_Premier_League_2025.svg/revision/latest/scale-to-width-down/300?cb=20260225151004" ;;
            *"FOOTBALL"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/0/0f/Sky_Sports_Football_2025.svg/revision/latest/scale-to-width-down/300?cb=20260227133651" ;;
            *"MIX"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/f/f2/Sky_Sports_Mix_2025.svg/revision/latest/scale-to-width-down/284?cb=20260226213635" ;;
            *"ACTION"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/e/e5/Sky_Sports_Action_2026.svg/revision/latest/scale-to-width-down/300?cb=20260225145802" ;;
            *"F1"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/5/5c/Sky_Sports_F1_2025.svg/revision/latest/scale-to-width-down/284?cb=20260225145601" ;;
            *"RACING TV"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/d/d0/Racing_TV_2018.svg/revision/latest/scale-to-width-down/300?cb=20210627150820" ;;
            *"RACING"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/f/fe/Sky_Sports_Racing_2025.svg/revision/latest/scale-to-width-down/300?cb=20260226213414" ;;
            *"TENNIS"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/f/f0/Sky_Sports_Tennis_2025.svg/revision/latest/scale-to-width-down/340?cb=20260226213228" ;;
            *"GOLF"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/9/90/Sky_Sports_Golf_2025.svg/revision/latest/scale-to-width-down/300?cb=20260226212716" ;;
            *"CRICKET"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/1/1e/Sky_Sports_Cricket_2025.svg/revision/latest/scale-to-width-down/300?cb=20260225150529" ;;
            *"+"*) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/6/66/Sky_Sports_Plus_2025.svg/revision/latest/scale-to-width-down/340?cb=20260225151219" ;;
            *) tvg_logo="https://static.wikia.nocookie.net/logopedia/images/b/b7/Sky_Sports_2025.svg/revision/latest/scale-to-width-down/300" ;;
        esac

    elif [[ "$line" == Link:* ]]; then
        # লিংক থেকে আবর্জনা কেটে ফ্রেশ ইউআরএল বের করা হচ্ছে
        raw_url=$(echo "$line" | grep -o 'http.*' | sed 's/&play_token=.*//')
        
        # ১. সাবফোল্ডারে একদম ক্লিন ৪ লাইনের ফাইল তৈরি
        cat << INLINE_EOF > "$FOLDER_NAME/$file_name"
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=4000000,RESOLUTION=1920x1080
$raw_url
INLINE_EOF

        # ২. মেইন প্লেলিস্টে ডাটা যুক্ত করা (tvg-name সরাসরি ক্লিন নাম হবে)
        echo "#EXTINF:-1 tvg-name=\"$clean_name\" tvg-logo=\"$tvg_logo\" group-title=\"UK SKY SPORTS\", $original_name" >> sky-sports.m3u
        echo "$GITHUB_RAW_URL/$file_name" >> sky-sports.m3u
    fi
done < raw_data.txt

# টেম্পোরারি ফাইল মুছে ফেলা
rm raw_data.txt
