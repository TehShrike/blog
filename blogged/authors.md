It's important to recognize the people that have contributed to your project,
but it can be annoying to keep your project's AUTHORS file up to date, and
annoying to ask everyone to add themselves in the correct format.

So I did what any good engineer should do, and automated the process! I added a
simple `make` target that will update the authors file based on the current Git
history:

<p>
[bash]
    # Run this command to update AUTHORS.md with the latest contributors.
    authors:
        echo "Authors\n=======\nWe'd like to thank the following people for their contributions.\n\n" > AUTHORS.md
        git log --raw | grep "^Author: " | sort | uniq | cut -d ' ' -f2- | sed 's/^/- /' >> AUTHORS.md
[/bash]
</p>

Essentially, that snippet gets every author from the git history, sorts and
unique-ifies the list, strips the word "Author: " from the line, and outputs
the new list to the AUTHORS.md file. Now updating the authors list is as easy
as running `make authors` from the command line.
