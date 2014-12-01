# "Invalid Username or Password": a useless security measure

<style>
.screenshot {
    border: 1px solid #ccc;
}
</style>

Login attempts fail because computer users can't remember their email or didn't
input the right password. Most websites on the Internet won't tell you which
one is actually incorrect.

### Amazon:

<img class="screenshot" src='https://api.monosnap.com/image/download?id=XEX9FAaZz1JDmMW4RyxaHZIa5rZinK' alt='Amazon' />

### Shoprunner:

<img class="screenshot" src='https://api.monosnap.com/image/download?id=UHSjx1m4JFTGhfeCqBzj7sQNDO8tJM' alt='Shoprunner' />

### Hacker News:

<img class="screenshot" src='https://api.monosnap.com/image/download?id=J16ZvW7eg6XZgx7o4BXie456EhZY8t' alt='HN' />

If you tell an attacker the email address is wrong, they'll try a different
one. If you tell them the password is wrong, then an attacker knows that
the username is correct, and can go on to try a bunch of passwords for that
username until they hit the right one. So sites won't tell you which one is
wrong, to try and avoid the information disclosure.

Unfortunately **this assumes that there's no other way for an attacker to
discover whether a username/email address is registered for a service**. This
assumption is incorrect.

99.9% of websites on the Internet will only let you create one account for each
email address. So if you want to see if an email address has an account, **try
signing up for a new account with the same email address.**

Here are all of the websites above, confirming that an account exists with my
email address/username:

### Amazon:

<img class="screenshot" src='https://api.monosnap.com/image/download?id=rfKXukU3xNRC8MyVJgHT9JsY35bXdp' alt='Amazon' />

### Shoprunner:

<img class="screenshot" src='https://api.monosnap.com/image/download?id=Cj1yXPgu4ANy9Pztb5Bcf6D1iP5B6m' alt='Shoprunner' />

### Hacker News:

<img class="screenshot" src='https://api.monosnap.com/image/download?id=lLTXlGInEtYEGQeVKGlQEUuIQCmafJ' alt='HN' />

So what we've done by promoting "Invalid username or password" is made our
login form UX much, much worse, without increasing the security of our product.

If people don't log in to your site every day (every site on the web except
Facebook or Google), not remembering credentials is a huge barrier to accessing
your site. Don't make it harder by adding a vague error message that doesn't
increase your site's security at all.

*But there's a tradeoff there between security and UX*, I hear you say. I am
trying to show you there is no tradeoff; you are choosing between a better user
experience and a worse user experience.

## What should I do instead?

Accept that your login page and your signup pages are targets for malicious
behavior, and design appropriately.

- Rate limiting can go a long way to preventing brute force attacks. To find
email addresses, an attacker is going to need to try a lot of email addresses
and/or a lot of passwords, and get a lot of them wrong. Consider throttling
invalid login attempts by IP address or subnet. Check submitted passwords
against a dictionary of common passwords (123456, monkey, etc) and ban that
traffic extra hard. Exponential backoff (forcing attackers to try again after
1, 2, 4, 8, 16.. seconds) is useful as well.

- Give guidance to users about creating strong passwords. Allow easy
integration with LastPass or 1Password.

- Add a 2-factor auth option to your website. Encourage users to use it.

- Warn users about malicious behavior ("someone is trying to snoop your
  password") and contact them about suspicious logins.
