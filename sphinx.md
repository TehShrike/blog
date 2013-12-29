# Using Sphinx to create links in readme's

This will be short, but it seems there's some difficulty doing this, so
I thought I'd share.

The gist is, any time you reference a class or method in your own library, in
the Python standard library, or in another third-party extension, you can
provide a link directly to that project's documentation. This is pretty amazing
and only requires a little bit of extra work from you. Here's how.

### The Simplest Type of Link

Just create a link using the full import path of the class or attribute or
method. Surround it with backticks like this:

    Use :meth:`requests.Request.get` to make HTTP Get requests.

That link will show up in text as:

> Use [requests.Request.get][get] to make HTTP Get requests.

[get]: http://docs.python-requests.org/en/latest/api/#requests.get

There are a few different types of declarations you can use at the beginning of
that phrase:

    :attr:
    :class:
    :meth:
    :exc:

The full list is [here][cross-reference].

[cross-reference]: http://sphinx-doc.org/latest/domains.html#cross-referencing-python-objects

### I Don't Want to Link the Whole Thing

To specify just the method/attribute name and not any of the modules or classes
that precede it, use a squiggly, like this:

    Use :meth:`~requests.Request.get` to make HTTP Get requests.

That link will show up in text as:

> Use [get][get] to make HTTP Get requests.

### I Want to Write My Own Text

This gets a little trickier, but still doable:

    Use :meth:`the get() method <requests.Request.get>` to make HTTP Get requests.

That link will show up in text as:

> Use [the get() method][get] to make HTTP Get requests.

### I want to link to someone else's docs

In your `docs/conf.py` file, add `'sphinx.ext.intersphinx'` to the end of the
`extensions` list near the top of the file. Then, add the following anywhere
in the file:

[python]
    # Add the "intersphinx" extension
    extensions = [
        'sphinx.ext.intersphinx',
    ]
    # Add mappings
    intersphinx_mapping = {
        'urllib3': ('http://urllib3.readthedocs.org/en/latest', None),
        'python': ('http://docs.python.org/3', None),
    }
[/python]

You can then link to other projects' documentation and then reference it the
same way you do your own projects, and Sphinx will magically make everything
work.

### I want to write the documentation inline in my source code and link to it

Great! I love this as well. Add the `'sphinx.ext.autodoc'` extension, then
write your documentation. There's a full guide to the inline syntax [on the
Sphinx website][autodoc]; confusingly, it is not listed on the autodoc page.

[python]
    # Add the "intersphinx" extension
    extensions = [
        'sphinx.ext.autodoc',
    ]
[/python]

[autodoc]: http://sphinx-doc.org/latest/domains.html#info-field-lists

Hope that helps! Happy linking.
