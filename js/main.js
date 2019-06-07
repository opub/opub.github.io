// Cycle banner background images
var banner = 0;
function cycleBanner() {
  banner = banner == 9 ? 0 : banner+1;
  var b = document.getElementById('banner');
  b.style.backgroundImage = "url('images/back" + banner + ".jpg')";
  setTimeout(cycleBanner, 30000);
}
setTimeout(cycleBanner, 30000);

$(document).ready(function() {
  AOS.init( {
    // uncomment below for on-scroll animations to played only once
    // once: true  
  }); // initialize animate on scroll library
});

//password utilities
const UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const LOWER = 'abcdefghijklmnopqrstuvwxyz';
const NUMBER = '0123456789';
const SYMBOL = '~`!@#$%^&*()-=_+{}|[]\\:";\'<>?,./';
function generatePasswords() {
    let chars = '';
    if ($('#pwupper').is(':checked')) chars += UPPER;
    if ($('#pwlower').is(':checked')) chars += LOWER;
    if ($('#pwnumber').is(':checked')) chars += NUMBER;
    if ($('#pwsymbol').is(':checked')) chars += SYMBOL;
    if ($('#pwreadable').is(':checked')) chars = chars.replace(/[0O1lI\|]/g, '');
    let size = $('#pwlength').val();
    let pwds = '';
    if (chars.length > 0) {
        for (var i=0; i < 5; i++) {
            for (var j=0; j < size; j++ ) {
                pwds += chars[Math.floor(Math.random() * chars.length)];
            }
            if (i < 4) pwds += '\n\n';
        }
    }
    else {
        pwds = 'Select at least one type of character to include.'
    }
    $('#passwordlist').text(pwds);
}
function checkPassword() {
    let pwd = $('#pwstrength').val();
    let result = zxcvbn(pwd);
    $('#passwordrating').attr('class', 'strength' + result.score);
    let rating = 'DO NOT USE THIS';
    switch (result.score) {
        case 1: rating = 'Pretty Weak'; break;
        case 2: rating = 'You Can Do Better'; break;
        case 3: rating = 'Better'; break;
        case 4: rating = 'Very Good'; break;
    }
    $('#passwordrating').text(rating);
    let feedback = '';
    if (result.score <= 2) {
        feedback += result.feedback.warning;
        if (feedback.length > 0) feedback += '<br>';
        feedback += result.feedback.suggestions.join('<br>');
    }
    $('#passwordfeedback').html(feedback);
}

// Smooth scroll for links with hashes
$('a.smooth-scroll')
.click(function(event) {
  // On-page links
  if (
    location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') 
    && 
    location.hostname == this.hostname
  ) {
    // Figure out element to scroll to
    var target = $(this.hash);
    target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
    // Does a scroll target exist?
    if (target.length) {
      // Only prevent default if animation is actually gonna happen
      event.preventDefault();
      $('html, body').animate({
        scrollTop: target.offset().top
      }, 1000, function() {
        // Callback after animation
        // Must change focus!
        var $target = $(target);
        $target.focus();
        if ($target.is(":focus")) { // Checking if the target was focused
          return false;
        } else {
          $target.attr('tabindex','-1'); // Adding tabindex for elements not focusable
          $target.focus(); // Set focus again
        };
      });
    }
  }
});
