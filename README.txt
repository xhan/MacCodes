* Why MacCode?

A lot of us wanted to have a place to centralize code that can be used by everyone within the Mac community. Cocoa, Carbon, Applescript, etc etc.



* About

- The why:

MacCode started as a discussion at C4(0). Wolf, you will appreciate that this happened in the hallway, or close enough to it. A few of us decided that it was just frustrating to find anything useful, and if we had a central location for code it'd just rock.

MacCode was started shortly after that.

- The what:

The MacCode repo is a repository hosted on Google Code with a bunch of stuff in it. Notables:

- PSMTabBarControl
- Aquatic Prime

Everything is 3 clause BSD.

This project also includes source code from other projects in the opensource-bsd-externals directory. You will only get the opensource-bsd-externals setup if you update the release with an svn (subversion) client.

- The when:

We're aiming to put out a source release every 3 months of whatever is currently available in trunk in the subversion repo. This timeline may not always be exact though.


* How to use this distribution:

This distribution is an archive of a subversion (svn) working copy. Basically this means that you can update this archive at any time with what is online.


* Instructions for checking out code:

If you want the external projects checked out (projects not hosted on Google Code, but which are useful)

svn co http://maccode.googlecode.com/svn/trunk/ maccode

If you do not want the externals (they can take up a bit of space)

svn co http://maccode.googlecode.com/svn/trunk/ maccode --ignore-externals 


* Getting a commit bit.

Email Chris Forsythe http://trac.adiumx.com/wiki/the_tick and he will get you access. All code you submit needs to be 3 clause BSD.

