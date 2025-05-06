rm -rf source
rm -rf source_tmp

pipx install yt-dlp[default,curl_cffi]
yt-dlp --impersonate chrome https://opensource.truthsocial.com/mastodon-current.zip -o "mastodon-current.zip"
unzip mastodon-current.zip -d source_tmp

mv source_tmp/open\ source source

rm -rf source_tmp
rm mastodon-current.zip
