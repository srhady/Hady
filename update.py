import re, requests

URL = "https://tvsen6.aynascope.net/etv/tracks-v1a1/mono.ts.m3u8"

def get_updated_url():
    r = requests.get(URL)
    if r.status_code == 200:
        return r.url
    return URL

def update_m3u():
    with open("Own.m3u", "r") as f:
        lines = f.readlines()
    updated = []
    for line in lines:
        if "tvsen6.aynascope.net" in line:
            updated.append(get_updated_url() + "\n")
        else:
            updated.append(line)
    with open("Own.m3u", "w") as f:
        f.writelines(updated)

update_m3u()
