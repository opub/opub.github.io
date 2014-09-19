---
layout: page
title: Welcome
tagline: Paying rent on success
---
{% include JB/setup %}

{% for post in site.posts %}
  <h2>{{ post.title }}</h2>
  <h3>{{ post.date | date_to_string }}</h3>
  {{ post.excerpt }}
  {% if post.content contains '<!--more-->' %}
    <p>{{ post.content | split:'<!--more-->' | first }}</p>
  {% else %}
    <p>{{ post.content | truncatewords:50 | strip_html }}</p>
  {% endif %}
  <a href="{{ BASE_PATH }}{{ post.url }}">Read More...</a>
{% endfor %}
