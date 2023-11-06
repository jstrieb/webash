# webash

Webash (web + bash) creates web interfaces for console applications by
extracting flags and options from programs' help text. With webash, you can run
shell commands from any phone or laptop without leaving the browser.

<div align="center">
<img src="https://github.com/jstrieb/webash/assets/7355528/0a15342f-b97d-4b80-8e66-a3dede595059" width="90%" />
</div>

Webash is specifically built to be used with
[QuickServ](https://github.com/jstrieb/quickserv), a simple web server with a
fresh take on the common gateway interface (CGI). 

QuickServ serves static files directly, but executes scripts and programs. It
passes GET parameters to executing programs as command-line arguments, and
passes POST data on standard input. Then, it responds to the user by wrapping
any data echoed to the standard output with the correct MIME type and the
appropriate HTTP headers (e.g., for CORS).

Using QuickServ, any console application becomes a web application back end
with no additional changes. Before webash, creating a front end interface was
the most tedious part of using QuickServ. Now, webash automates the process by
creating web interfaces from any program's help text.

In other words, with QuickServ and webash, it is trivial to turn any console
program into a web application with a functional front end and back end.

Webash, itself, is a portable, POSIX-compatible shell script that can be run
offline to generate static HTML, or online via QuickServ to dynamically
generate interfaces for console programs.


# Examples

Example web interfaces have been generated for a handful of common shell
commands. 

<!--
  Generated with:

  ls examples/ \
    | grep -v index \
    | sed 's,^\(.*\).html$,- [`\1`](https://jstrieb.github.io/webash/\1.html),g'
-->

- [`dir`](https://jstrieb.github.io/webash/dir.html)
- [`gas`](https://jstrieb.github.io/webash/gas.html)
- [`htop`](https://jstrieb.github.io/webash/htop.html)
- [`hwclock`](https://jstrieb.github.io/webash/hwclock.html)
- [`install`](https://jstrieb.github.io/webash/install.html)
- [`mount`](https://jstrieb.github.io/webash/mount.html)
- [`tar`](https://jstrieb.github.io/webash/tar.html)
- [`xargs`](https://jstrieb.github.io/webash/xargs.html)


# Quick Start & Installation

For most use cases, webash should be used offline to generate an interface that
gets manually modified before being used with QuickServ. But for demonstration
purposes, the following steps will set up webash to dynamically generate
interfaces for any command line application on the host system's `PATH`.

1. [Install QuickServ.](https://github.com/jstrieb/quickserv/#get-started)
1. Clone this repository locally and `cd` into the repository root directory.

   ``` bash
   git clone https://github.com/jstrieb/webash.git
   cd webash
   ```
1. Optionally, allow the interface to run commands (arbitrary remote code
   execution on the server computer – **very unsafe!**) by [uncommenting these
   lines in the
   code](https://github.com/jstrieb/webash/blob/46b3ee14fec3162d4863f5b22ced987db471f117/index.sh#L124-L129).
1. Run `quickserv` in the repo root.
1. Go to <http://localhost:42069> in the browser.
1. Pick a command-line program, and check out the generated interface.


## Static HTML

It is safer to use webash to generate static HTML interfaces for individual
console applications than to run it dynamically.

```
# Install webash into the PATH (only needs to be done once)
sudo curl \
  --location \
  -o /usr/local/bin/webash \
  "https://github.com/jstrieb/webash/raw/master/index.sh"
sudo chmod +x /usr/local/bin/webash 

# Generate HTML for your program with webash
webash links/my_program.py > index.html

# Run QuickServ to serve the front end and execute the back end
quickserv
```


# Project Status & Contributing

This project is actively maintained, but no new features are planned. If there
are no recent commits, it means that everything is running smoothly!

Please [open an issue](https://github.com/jstrieb/webash/issues/new) with any
bugs, suggestions, or questions. 


## Known Issues

Webash can only automatically extract command-line arguments from the most
common help text formats. It uses simple regular expression-based normalization
and pattern matching, and is therefore somewhat brittle. It is also not
particularly performant.


# Support the Project

There are a few ways to support the project:

- Star the repository and follow me on GitHub
- Share and upvote on sites like Twitter, Reddit, and Hacker News
- Report any bugs, glitches, or errors that you find
- Build and share your own projects made with QuickServ

These things motivate me to to keep sharing what I build, and they provide
validation that my work is appreciated! They also help me improve the project.
Thanks in advance!

If you are insistent on spending money to show your support, I encourage you to
instead make a generous donation to one of the following organizations. By
advocating for Internet freedoms, organizations like these help me to feel
comfortable releasing work publicly on the Web.

- [Electronic Frontier Foundation](https://supporters.eff.org/donate/)
- [Signal Foundation](https://signal.org/donate/)
- [Mozilla](https://donate.mozilla.org/en-US/)
- [The Internet Archive](https://archive.org/donate/index.php)
