# How To Submit Forms with Javascript

Do you write forms on the Internet? Are you planning to send them to your
server with Javascript? You should read this.

### The One-Sentence Summary

It's okay to submit forms with Javascript. Just **don't break the internet.**

### What Do You Mean, Break the Internet?

Your browser is an advanced piece of software that functions in a specific way,
often for very good reasons. Ignore these reasons and annoy your users. User
annoyance translates into lower revenue for you.

Here are some of the ways your Javascript form submit can break the Internet.

### Submitting to a Different Endpoint Than the Form Action

A portion of your users are browsing the web without Javascript enabled. Some
of them, like my friend Andrew, are paranoid. Others are on slow connections
and want to save bandwidth. Still others are blind and browse the web with the
help of screen readers.

All of these people, when they submit your form, will not hit your fancy
Javascript event handler; they will submit the form using the default `action`
and `method` for the form - which, if unspecified, default to a GET to the
current page. Likely, this does not actually submit the form. Which leads to my
favorite quote from Mark Pilgrim:

<a href="http://diveinto.html5doctor.com/history.html">
    <img class="inline" src="https://www.evernote.com/shard/s265/sh/58a618f8-25e7-4b7d-bd0c-429fbb12ce36/5b00b0ea042e307f50677bc6fe0b4697/res/342e963a-6eb4-412e-a008-8044b95eeb73/skitch.png" alt="Jakob Nielsen's dog" />
</a>

There is an easy fix: make the form `action` and `method` default to the same
endpoint that you are POSTing to with Javascript. 

You are probably returning some kind of JSON object with an error or success
message and then redirecting the user in Javascript. Just change your server
endpoint to redirect if the request is not an AJAX request. You can do this
because all browsers attach an `X-Requested-With: XMLHttpRequest` HTTP header
to asynchronous Javascript requests.

### Changing Parameter Names

Don't change the names of the submitted parameters in Javascript - just
submit the same names that you had in your form. In jQuery this is easy, just
call the [`serialize`][serialize] method on the form.

[serialize]: http://api.jquery.com/serialize/

[javascript]
var form = $("#form-id");
$.post('endpoint', $(form).serialize(), function(response) {
    // do something with the response.
});
[/javascript]

### Attaching the Handler to a Click Action

Believe it or not, there are other ways of submitting a form besides clicking
on the `submit` button. Screen readers, for example, don't `click`, they submit
the form. Also there are lots of people like me who use tab to move between
form fields and press the spacebar to submit forms. This means if your form
submit starts with:

[javascript]
$("#submit-button").click(function() {
    // Submit the form.
});
[/javascript]

**You are doing it wrong** and breaking the Internet for people like me. You
would not believe how many sites don't get this right. Examples in the past
week: Wordpress, Mint's login page, JetBrains's entire site.

The correct thing to do is attach the event handler to the form itself.

[javascript]
$("#form-id").submit(function() {
    // Write code to submit the form with Javascript
    return false; // Prevents the default form submission
});
[/javascript]

This will attach the event to the form however the user submits it. Note the
use of `return false` to avoid submitting the form.

### Validation

It's harder to break the Internet with validation. To give fast feedback loop
to the user, you should detect and prevent invalid input on the client side.

The annoying thing is you have to do this on both the client side and the
server side, in case the user gets past the client side checks. The good news
is the browser can help with most of the easy stuff. For example, if you want
to check that an email address is valid, use the "email" input type:

[html]
<input type="email" />
[/html]

Then your browser won't actually submit a form that doesn't have a valid email.
Similarly you can note required fields with the `required` HTML attribute. This
makes validation on the client a little easier for most of the cases you're
trying to check for.

### Summary

You *can* submit forms with Javascript, but most of the time you'll have to put
in extra effort to duplicate functionality that already exists in your browser.
If you're going to go down that road, please put in the extra effort.

