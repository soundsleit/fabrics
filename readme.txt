Fabrics : by Scott Smallwood

Fabrics is ChucK-based musical instrument that can be played in many different ways, as well as in groups.  The basic idea is that each player performs with a textured instrument made up of a dense "fabric" of sine tones which are organized into an arbitrary pitch system.  The system works as follows:

A pitch table is created which consists of a certain number of bases, or "octaves," which are related to a single fundamental pitch.  The table populates with pitches that include a number of "steps" in between the bases.  Then a series of six voices are randomly chosen from this collection, each of which include eight partials which are also related to this pitch table.

The chuck patch can be run with arguments that determine the character of the pitch table.

For example:

chuck -c6 --blocking fabrics.ck:90:4:2:7

The first argument determines the fundamental pitch. The second argument determines the number of bases in the table.  The third determines the factor, or ratio of the basis, and the fourth number determines the number of steps in between the bases.

The example above creates a fundamental pitch of 90, with 4 bases at a ratio of 2:1, with seven steps between each base.

This patch should be run in the Terminal.  The -c6 flag simply determines the number of channels (could be -c2 for stereo).  The blocking flag seems to be necessary. 

--

As soon as a fabric is turned on, all of the sine tones will begin with no drift, meaning that the frequencies will stay static.  Changing the drift parameter causes the voices to all begin to drift away from the original pitch.  This drift can be controlled or eliminated using the “drift” keys (up or down).  A value of 0 means that there will be no drift.  

In addition, there are a series of "spectral bumps" that can be played by striking certain keys.  These will cause momentary swells in certain frequency areas.

There is also a server control program called fabContr.ck.  This patch will allow some global modifications to all machines fabric texture.  The server can "flatten" all players (remove drift), and can also cause "skipping" to occur throughout the group texture.

Play around and have fun!

—

For best results with network performance, please launch the patch using the unix script “fab.”  This script will ensure that your machine’s local name will be sent to the server (assuming it is running on another machine on your local area network).  Once the server receives the name, that machine is added to it’s client devices.

The script works as follows:

./fab 2 300 5 2 8

(the parameter: 2 is the number of channels (can be any number of channels), and 300 5 2 8 refer to the tuning system mentioned above.  These parameters are passed on as flags and will determine the pitch structure of the fabric of sound.
