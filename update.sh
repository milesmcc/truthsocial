rm -rf source
rm -rf source_tmp

python3 -m venv .venv && .venv/bin/pip install curl_cffi
.venv/bin/python3 -c "from curl_cffi import requests; r = requests.get('https://opensource.truthsocial.com/mastodon-current.zip', impersonate='chrome', timeout=300); open('mastodon-current.zip','wb').write(r.content)"
unzip mastodon-current.zip -d source_tmp

mv source_tmp/open\ source source

rm -rf source_tmp
rm mastodon-current.zip
