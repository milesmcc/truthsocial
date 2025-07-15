rm -rf source
rm -rf source_tmp

sudo apt install torsocks
pipx install yt-dlp[default,curl_cffi]
# Rotate IP addresses (by restarting Tor) if we get captcha-blocked by Truth Social
until torsocks yt-dlp --impersonate chrome https://opensource.truthsocial.com/mastodon-current.zip -o "mastodon-current.zip";do sudo service tor restart;done
unzip mastodon-current.zip -d source_tmp

mv source_tmp/open\ source source

rm -rf source_tmp
rm mastodon-current.zip
