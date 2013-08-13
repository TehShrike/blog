# Eliminating more trivial inconveniences

I really enjoyed Sam Saffron's post about [eliminating trivial inconveniences
in his development process][inconveniences]. This resonated with me as I tend
to get really distracted by minor hiccups in the development process (page
reload taking >2 seconds, switch to a new tab, etc). I took a look at my
development process and found a few easy wins.

### Automatically run the unit tests in the current file

Twilio's PHP test suite are really slow - we're sloppy about trying to have
unit tests avoid hitting the disk, which means that the suite takes a while to
run. I wrote a short vim command that will run only the tests in the current
file. This tends to make the test iteration loop much, much faster and I can
run the entire suite of tests once the current file is passing. The `<leader>`
function in Vim is excellent and I recommend you become familiar with it.

    nnoremap <leader>n :execute "!" . "/usr/local/bin/phpunit " . bufname('%') . ' \| grep -v Configuration \| egrep -v "^$" '<CR>

`bufname('%')` is the file name of the current Vim buffer, and the last two
commands are just grepping away output I don't care about. The result is
awesome:

<img src="http://content.screencast.com/users/kevinburke/folders/Jing/media/b0cc0ee8-eb80-48c8-8676-bbb8b0fe98c6/00000001.png" alt="Unit test result in vim" />

### Auto reloading the current tab when you change CSS

Sam has a pretty excellent MessageBus option that listens for changes to CSS
files, and auto-refreshes a tab when this happens. We don't have anything that
good yet but I added a vim leader command to refresh the current page in the
browser. By the time I switch from Vim to Chrome (or no time, if I'm viewing
them side by side), the page is reloaded.

    function! ReloadChrome()
        execute 'silent !osascript ' . 
                    \'-e "tell application \"Google Chrome\" " ' .
                    \'-e "repeat with i from 1 to (count every window)" ' .
                    \'-e "tell active tab of window i" ' . 
                    \'-e "reload" ' .
                    \'-e "end tell" ' .
                    \'-e "end repeat" ' .
                    \'-e "end tell" >/dev/null'
    endfunction

    nnoremap <leader>o :call ReloadChrome()<CR>:pwd<cr>

Then I just hit `<leader>o` and Chrome reloads the current tab. This works even
if you have the "Developer Tools" open as a separate window, and focused - it
reloads the open tab in every *window* of Chrome.

### Pushing the current git branch to origin

It turns out that the majority of my git pushes are just pushing the current
git branch to origin. So instead of typing `git push origin <branch-name>` 100
times a day I added this to my `.zshrc`:

[bash]
    push\_branch() {
        branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
        git push $1 $branch
    }
    autoload push\_branch
    alias gpob='push\_branch origin'
[/bash]

I use this for git pushes almost exclusively now.

### Auto reloading our API locally

The Twilio API is based on the open-source [`flask-restful`][fr] project,
running behind [uWSGI][uwsgi]. One problem we had was changes to the
application code would require a full uWSGI restart, which made local
development a pain. Until recently, it was pretty difficult to get new Python
code running in uWSGI besides doing a manual reload - you had to implement
a file watcher yourself, and then communicate to the running process. But last
year uWSGI enabled the `py-auto-reload` feature, where uWSGI will poll for 
changes in your application and automatically reload itself. Enable it in your
uWSGI config with

[bash]
py-auto-reload = 1   # 1 second between polls
[/bash]

Or at the command line with `uwsgi --py-auto-reload=1`.

### Conclusion

These changes have all made me a little bit quicker, and helped me learn more
about the tools I use on a day to day basis. Hope they're useful to you as
well!

[inconveniences]: http://samsaffron.com/archive/2013/05/03/eliminating-my-trivial-inconveniences
[uwsgi]: http://uwsgi-docs.readthedocs.org/en/latest/
[fr]: https://github.com/twilio/flask-restful
