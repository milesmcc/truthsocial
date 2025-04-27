rm -rf source
rm -rf source_tmp

curl https://opensource.truthsocial.com/mastodon-current.zip > mastodon-current.zip
unzip mastodon-current.zip -d source_tmp

mv source_tmp/open\ source source

rm -rf source_tmp
rm mastodon-current.zip
