---
layout: post
category: gambling
title: "Blackjack Trainer"
date: 2015-02-18T01:40:36+00:00
tags: [blackjack, gambling, programming]
---

<script type="text/javascript" src="/assets/blackjack.js">
</script>

I found out that my wife had planned a trip to Atlantic City for me and a bunch of guys for my birthday.  So I wanted to brush up on blackjack basic strategy by making my own training page.  

<!--more-->

Most of the blackjack training sites and apps out there are either:

1. loaded with ads
2. too focused on the UI and not configurable for the rules I wanted
3. buggy in terms of the correct basic strategy

My goal was to develop a simple blackjack trainer that was specific to the rules that you are most likely to find in the Atlantic City casinos.  I didn't care about the UI or the betting in this case.  I just wanted something similar to flash cards that would help me figure out scenarios that I'd need to brush up on.

<h2>Dealer Card: <span id="dealer"></span></h2>

<h2>Player Hand: <span id="player"></span></h2>

<ul class="tag_box inline">
<li><a href="#" onclick="play('S')">Stand</a></li>
<li><a href="#" onclick="play('H')">Hit</a></li>
<li><a href="#" onclick="play('D')">Double</a></li>
<li><a href="#" onclick="play('Ds')">Dbl/Stand</a></li>
<li id="P"><a href="#" onclick="play('P')">Split</a></li>
</ul>

<h3 id="message"></h3>

<h4 id="stats"></h4>

<div id="wrong"></div>

<script type="text/javascript">
deal();
</script>