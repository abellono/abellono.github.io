---
layout: default
name: roomservice
title: Roomservice Driver
description: The driver management app for Roomservice.no
bundle_id: no.abello.roomservicedriverenterprise
---
{% assign matching_builds = site.github.releases | where: "name", page.bundle_id | sort: "tag_name" | reverse %}

{% if length == 0 %}
<h1 class="center">No builds yet! :(</h1>
{% else %}

{% assign latest_version = matching_builds | first %}
{% assign manifest_asset = latest_version.assets | where: "name", "manifest.plist" | first %}
{% assign picture_asset = latest_version.assets | where: "name", "57.png" | first %}

<h3 class="center">
	<a class="btn install" href="itms-services://?action=download-manifest&url={{ manifest_asset.browser_download_url }}" style="text-align: center;">
    	<img src="{{ picture_asset.browser_download_url }}"/>
    	Click here to download latest version!
	</a>
</h3>

---
<h3 class="center">
Old Versions
</h3>
{% for build in matching_builds %}{% assign manifest_asset = latest_version.assets | where: "name", "manifest.plist" | first %}
<h3 class="center"><a href="itms-services://?action=download-manifest&url={{ manifest_asset.browser_download_url }}">v{{build.tag_name}}</a></h3>{% endfor %}
{% endif %}
