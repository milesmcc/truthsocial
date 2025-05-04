rm -rf source
rm -rf source_tmp

pipx install yt-dlp[curl_cffi]
yt-dlp --impersonate chrome --force-ipv4 https://opensource.truthsocial.com/mastodon-current.zip -o "mastodon-current.zip"||yt-dlp --impersonate chrome --force-ipv6 https://opensource.truthsocial.com/mastodon-current.zip -o "mastodon-current.zip"
unzip mastodon-current.zip -d source_tmp

mv source_tmp/open\ source source

rm -rf source_tmp
rm mastodon-current.zip
