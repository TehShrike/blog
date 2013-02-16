## Helping Beginners Get HTML Right

If you've ever tried to teach someone HTML, you know how hard it is to get the
syntax right. It's a perfect storm of awfulness.

* Newbies have to learn all of the syntax, in addition to the names of HTML
elements. They don't have the pattern matching skills (yet) to notice when
their XML is not right, or the domain knowledge to know it's spelled "href" and
not "herf".

* The browser doesn't provide feedback when you make mistakes - it will render
your mistakes in unexpected and creative ways. Miss a closing tag and watch
your whole page suddenly acquire italics, or get pasted inside a textarea. Miss
a quotation mark and half the content disappears. Add in layouts with CSS and
the problem doubles in complexity.

* Problems tend to compound. If you make a mistake in one place and
don't fix it immediately, you can't determine whether future additions are
correct.

This leads to a pretty miserable experience getting started - people
should be focused on learning how to make an amazingly cool thing in their
browser, but instead they get frustrated trying to figure out why the page
doesn't look right. 

##### Let's Make Things A Little Less Awful

What can we do to help? The existing tools to help people catch HTML mistakes
aren't great. Syntax highlighting helps a little, but sometimes [the errors
look as pretty as the actual text][error]. XML validators are okay, but tools
like [HTML Validator][validator] spew out red herrings as often as they do real
answers. Plus, you have to do work - open the link, copy your HTML in, read the
output - to use it.

**We can do better**. Most of the failures of the current tools are due to the
complexity of HTML - which, if you are using all of the features, is [Turing
complete][turing]. But new users are rarely exercising the full complexity of
HTML5 - they are trying to learn the principles. Furthermore the mistakes they
are making follow a Pareto distribution - a few problems cause the majority of
the mistakes.

##### Catching Mistakes Right Away

To help with these problems I've written an validator which checks for the most
common error types, and displays feedback to the user immediately when they
refresh the page - so they can instantly find and correct mistakes. It works in
the browser, on the page you're working with, so you don't have to do any extra
work to validate your file. 

Best of all, you can drop it into your HTML file in one line:

[html]
<script type="text/javascript" src="https://raw.github.com/kevinburke/tecate/master/tecate.js"></script>
[/html]

Then if there's a problem with your HTML, you'll start getting nice error
messages, like this:

<img class="inline" src="https://www.evernote.com/shard/s265/sh/1d0ef423-e5de-4e40-a110-fad2ccd01bef/22bffc622af4152261b63184ad4b8cae/res/645f4d83-f8a8-45c7-8ec7-b2fc12b5e16d/skitch.png" alt="error message" />

[Read more about it here][tecate], and use it in your next tutorial. I hope you
like it, and I hope it helps you with debugging HTML!

It's not perfect - there are a lot of improvements to be made, both in the
errors we can catch and on removing false positives. But I hope it's a start.

**PS:** Because the browser will edit the DOM tree to wipe the mistakes users
make, I have to use raw regular expressions to check for errors. I have a
feeling I will come to regret this. After all, when parsing HTML with regex,
it's clear that [the &lt;center> cannot hold][center]. I am **accepting** this
tool will give wrong answers on some HTML documents; I am **hoping** that the
scope of documents turned out by beginning HTML users is simple enough that the
center can hold.

[simple]: http://www.w3schools.com/schema/schema_simple.asp
[error]: https://www.evernote.com/shard/s265/sh/38008002-f293-4d05-8226-a6f1a2faaccd/16ae5e9fcdb7da4675fa1f942c97e63a
[validator]: http://validator.w3.org/
[turing]: https://github.com/elitheeli/stupid-machines/blob/master/rule110/rule110-full.html
[center]: http://stackoverflow.com/a/1732454/329700
[tecate]: https://github.com/kevinburke/tecate

