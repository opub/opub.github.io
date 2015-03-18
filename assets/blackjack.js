var H = "H";
var S = "S";
var P = "P";
var D = "D";
var Ds = "Ds";

//basic strategy for https://www.blackjackinfo.com/blackjack-basic-strategy-engine/?numdecks=8&soft17=s17&dbl=all&das=yes&surr=ns&peek=yes
var DEALER = ["2","3","4","5","6","7","8","9","T","A"];
var PLAYER = [];
for(var i=0; i < DEALER.length; i++)
{
	for(var j=0; j < DEALER.length; j++)
	{
		//ignore player blackjacks
		if((i != 8 && j != 9) && (i != 9 && j != 8)) {
			PLAYER[PLAYER.length] = DEALER[i] + DEALER[j];
		}
	}
}
var HARD = [];
for(var d=0; d < DEALER.length; d++)
{
	var dc = DEALER[d];
	HARD[dc] = [];
	for(var p=5; p < 21; p++)
	{
		if(p == 9 && d > 0 && d < 5 || p == 10 && d < 8 || p == 11 && d < 9) {
			HARD[dc][p] = D;
		} else if(p > 16 || p > 12 && d < 5 || p == 12 && d > 1 && d < 5) {
			HARD[dc][p] = S;
		} else {
			HARD[dc]["" + p] = H;
		}
	}
}
var SOFT = [];
for(var d=0; d < DEALER.length; d++)
{
	var dc = DEALER[d];
	SOFT[dc] = [];
	for(var p=3; p <= 10; p++)
	{
		if(p == 8 && d > 0 && d < 5) {
			SOFT[dc][p] = Ds;
		} else if(p < 8 && d > 2 && d < 5 || p == 7 && d > 0 && d < 3 || p > 4 && p < 7 && d == 2) {
			SOFT[dc][p] = D;
		} else if(p > 8 || p == 7 && d < 7) {
			SOFT[dc][p] = S;
		} else {
			SOFT[dc][p] = H;
		}
	}
}
var PAIR = [];
for(var d=0; d < DEALER.length; d++)
{
	var dc = DEALER[d];
	PAIR[dc] = [];
	for(var p=2; p <= 20; p+=2)
	{
		if(p == 10 && d < 8) {
			PAIR[dc][p] = D;
		} else if(p == 20 || p == 18 && (d == 5 || d > 7)) {
			PAIR[dc][p] = S;
		} else if(p < 16 && d > 5 || p == 8 && d < 3 || p > 6 && p < 14 && d == 5) {
			PAIR[dc][p] = H;
		} else {
			PAIR[dc][p] = P;
		}
	}
}

var streak = 0;
var good = 0;
var bad = 0;

function deal()
{
	var d = Math.floor(Math.random() * DEALER.length);
	var p = Math.floor(Math.random() * PLAYER.length);
	set("dealer", DEALER[d]);
	set("player", PLAYER[p]);

	document.getElementById("P").style.display = (PLAYER[p].charAt(0) == PLAYER[p].charAt(1)) ? "inline-block" : "none";
}

function play(action)
{
	var d = text("dealer");
	var p = text("player");
	var strategy;
	if(p.charAt(0) == p.charAt(1)) {
		strategy = PAIR;
	} else if (p.charAt(0) == "A" || p.charAt(1) == "A") {
		strategy = SOFT;
	} else {
		strategy = HARD;
	}
	var hand = card(p.charAt(0)) + card(p.charAt(1));
	var ideal = strategy[d][hand];
	if(action != ideal) {
		bad++;
		streak = 0;
		var msg = d + " - " + p + " = " + ideal + " (not " + action + ")";
		set("wrong", text("wrong") + "\n" + msg);
		set("message", "WRONG: " + msg);
	} else {
		good++;
		streak++;
		set("message", "");
	}
	stats();
	deal();
}

function card(face)
{
	if(face == "A") {
		return 1;
	} else if(face == "T") {
		return 10;
	} else {
		return parseInt(face);
	}
}

function stats()
{
	set("stats", "HANDS: " + (good+bad) + "\nCORRECT: " + (good/(good+bad)*100).toFixed(2) + "%\nSTREAK: " + streak);
}

function set(id, value)
{
	document.getElementById(id).innerText = value;
}

function text(id)
{
	return document.getElementById(id).innerText;
}