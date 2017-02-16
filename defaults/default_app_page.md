---
layout: default
name: @@@@NAME@@@@
title: @@@@PAGE_TITLE@@@@
description: @@@@PAGE_DESCRIPTION@@@@
bundle_id: @@@@BUNDLE_IDENTIFIER@@@@
---
{% assign matching_builds = site.data | where: "bundle_id", page.bundle_id | group_by: "version" %}
{% assign sorted_builds = matching_builds | sort: "name" | reverse %}

{% assign latest_version = sorted_builds | last %}
{% assign latest_version_build = latest_version.items | sort % | first %}

<h3 class="center">
    <a class="btn install" href="itms-services://?action=download-manifest&url={{ latest_version_build.manifest }}">Click here to download latest version!</a>
</h3>
---

<div class="versions">
### Old Versions

{% for builds in sorted_builds %}
#### Version {{ builds.name }}

<table class="center">
    <tr>
        <td>Builds</td>
        <td>Install</td>

        {% assign sorted_version_builds = builds.items | sort: "build" | reverse %}
        {% for build in sorted_version_builds %}
        <tr>
           <td>{{ build.build }}</td>
           <td>
               <a href="itms-services://?action=download-manifest&url={{ build.manifest }}">Install</a>
           </td>
        </tr>
        {% endfor %}
    </tr>
</table>
{% endfor %}
</div>