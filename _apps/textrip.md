---
layout: default
name: textrip
title: Textrip
description: App for scanning receipts
bundle_id: no.abello.textrip-enterprise
---
{% assign matching_builds = site.github.releases | where: "name", page.bundle_id | sort: "tag_name" | reverse %}

{% if length == 0 %}
<h1 class="center">No builds yet! :(</h1>
{% else %}

{% assign latest_version = matching_builds | first %}
{% assign manifest_asset = latest_version.assets | where: "name", "manifest.plist" | first %}

<h3 class="center">
    <a class="btn install" href="itms-services://?action=download-manifest&url={{ manifest_asset.browser_download_url }}">Click here to download latest version!</a>
</h3>

---

### Old Versions

Builds | Install
| :--- | ---: |{% for build in matching_builds %}{% assign manifest_asset = latest_version.assets | where: "name", "manifest.plist" | first %}
{{ build.tag_name }} | [Install](itms-services://?action=download-manifest&url={{ manifest_asset.browser_download_url }})
{% endfor %}
{% endif %}
