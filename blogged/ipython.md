Recently I've fallen in love with the [IPython Notebook][notebook]. It's the
Python REPL on steroids and I've probably just scratched the surface of what it
can actually do. This will be a short post because long posts make me feel pain
when I think about blogging more again. This is also really more about setting
up launchctl than IPython, but hopefully that's useful too.

Starting it from the command line is kind of a pain (it tries to save .ipynb
files in your current directory, it warns you to save files before closing tabs)
so I thought I'd just set it up to run in the background each time I run
ipython. Here's how you can get that set up.

### Create a virtualenv with iPython

First, you need to install the ipython binary, and the other packages you need
to run IPython Notebook.

[bash]
    # Install virtualenvwrapper, then source it
    pip install virtualenvwrapper
    source /path/to/virtualenvwrapper.sh
[/bash]

[bash]
mkvirtualenv ipython
pip install ipython tornado pyzmq
[/bash]

### Starting IPython When Your Mac Boots

Open a text editor and add the following:

[xml]
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>com.kevinburke.ipython</string>
      <key>ProgramArguments</key>
      <array>
          <string>/Users/kevin/.envs/ipython/bin/ipython</string>
          <string>notebook</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>StandardOutPath</key>
      <string>/Users/kevin/var/log/ipython.log</string>
      <key>StandardErrorPath</key>
      <string>/Users/kevin/var/log/ipython.err.log</string>
      <key>ServiceDescription</key>
      <string>ipython notebook runner</string>
      <key>WorkingDirectory</key>
      <string>/Users/kevin/.ipython_notebooks</string>
    </dict>
    </plist>
[/xml]

You will need to replace the word `kevin` with your name and relevant file
locations on your file system. I also save my notebooks in a directory called
.ipython\_notebooks in my home directory, you may want to add that as well.

Save that in `/Library/LaunchDaemons/<yourname>.ipython.plist`. Then change the
owner to `root`:

[bash]
sudo chown root:wheel /Library/LaunchDaemons/<yourname>.ipython.plist
[/bash]

Finally load it:

[bash]
sudo launchctl load -w /Library/LaunchDaemons/<yourname>.ipython.plist
[/bash]

If everything went ok, IPython should open in a tab. If it didn't go okay, check
`/var/log/system.log` for errors, or one of the two logfiles specified in your
plist.

### Additional Steps

That's it! I've also found it really useful to run an nginx redirecter locally,
as well as a new rule in `/etc/hosts`, so I can visit `http://ipython` and get
redirected to my notebooks. But that is a topic for a different blog post.

[notebook]: http://ipython.org/notebook.html
