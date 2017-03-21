gem 'octokit'

require 'octokit'

client = Octokit::Client.new(:access_token => "&&&KEY&&&")

name = ARGV[0]
version = ARGV[1]
ipa = ARGV[2]
id = ARGV[3]

release = client.create_release("abellono/abellono.github.io", "#{version}", {:target_commitish => "master", :name => "#{id}", :body => "Automatic release of #{name} version #{version}. Visit https://abellono.github.io/apps/#{name.downcase} to download this release."})

small_picture_asset = client.upload_asset(release.url, "./512.png", { :content_type => 'image/png', :name => '512.png' })
large_picture_asset = client.upload_asset(release.url, "./57.png", { :content_type => 'image/png', :name => '57.png' })
ipa_asset = client.upload_asset(release.url, ipa, { :content_type => 'application/octet-stream', :name => 'app.ipa' })

default_manifest = File.read('./manifest_default.plist')

default_manifest = default_manifest.sub('@@@@LINK@@@@', ipa_asset[:browser_download_url])
default_manifest = default_manifest.sub('@@@@SMALL_PIC@@@@', small_picture_asset[:browser_download_url])
default_manifest = default_manifest.sub('@@@@LARGE_PIC@@@@', large_picture_asset[:browser_download_url])
default_manifest = default_manifest.sub('@@@@BUNDLE_IDENTIFIER@@@@', id)
default_manifest = default_manifest.sub('@@@@NAME@@@@', name)
default_manifest = default_manifest.sub('@@@@VERSION@@@@', version.split(/\./)[0, 2].join('.'))

File.write('./manifest.plist', default_manifest)
client.upload_asset(release.url, "./manifest.plist", { :content_type => 'application/xml', :name => 'manifest.plist' })
