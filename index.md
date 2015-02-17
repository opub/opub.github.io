---
layout: page
title: Welcome
tagline: Paying rent on success
---
{% include JB/setup %}

{% for post in site.posts limit: 10 %}

<h2>{{ post.title }}</h2>
<h3>{{ post.date | date_to_string }}</h3>
{% if post.content contains '<!--more-->' %}
{{ post.content | split:'<!--more-->' | first }}
{% else %}
{{ post.content | truncatewords:50 | strip_html }}
{% endif %}
<a href="{{ BASE_PATH }}{{ post.url }}">Read More...</a>

{% endfor %}
