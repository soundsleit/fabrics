// ********************************** //
// Fabrics [fabrics_lap.ck] v. 3.0
// Apr 08 - Apr 09
// Updated, Sept. 2015
// 
// A Musical Instrument for Creating Textures and Sequences
//
// by Scott Smallwood
//  
//


"224.0.0.1" => string serverName;
1 => int call;

// channels
dac.channels() => int chanOut;

// tuning system magic numbers
6 => int voices;
8  => int partials;
60 => float baseFundamental;
5 => int bases;
1.5 => float baseFactor;
5 => int baseStep;
// init reverb mix
.01 => float verb;
// size of freq ridge (deviation)
0 => float devi;
// time between freq mods
30 => int ridgeSize;
// sequence on/off
0 => int space;
// pulse on/off
0 => int goPulse;

4::second => dur beat;


if (me.args() > 0)
{
	Std.atof(me.arg(0)) => baseFundamental;
	Std.atoi(me.arg(1)) => bases;
	Std.atof(me.arg(2)) => baseFactor;
	Std.atoi(me.arg(3)) => baseStep;
}

// total pitches
(bases - 1) * baseStep => int stepMax;

// main pitch table
float step[stepMax];

// random number seed
Std.rand2f(.01,.09) => float seed;
seed::second => now;

// trigger for new texture
1 => int bang;

// **** AUDIO CHAIN

// oscillator array
SinOsc s[voices][partials];
// main gain
Gain mainOut[chanOut];
// envelopes per channels
ADSR e[chanOut];
// reverberators per channels
JCRev mainRev[chanOut];
// submaster gains voice
Gain sub[voices];
// pans per voice
Pan2 p[voices];

// stereo chain
if (chanOut == 2)
{
	// main bus setup
	for (0 => int i; i < chanOut; i++) {
	  mainOut[i] => e[i] => mainRev[i] => dac.chan(i);
	  0.0 => mainOut[i].gain;
	  verb => mainRev[i].mix;
      e[i].set(50::ms, 0::ms, 1, 50::ms);
  }

	// voice assignments and panning
	for (0 => int i; i < voices; i++) {
		// spread voices evenly across field
 	 (((1. / (voices - 1)) * i) * 2) - 1 => p[i].pan;
 	 sub[i] => p[i].left => mainOut[0];
 	 sub[i] => p[i].right => mainOut[1];
	 1 => sub[i].gain;
 }
}

 // multi-channel chain
else
{
	// main bus setup
	for (0 => int i; i < chanOut; i++) {
	  sub[i] => mainOut[i] => e[i] => mainRev[i] => dac.chan(i);
      e[i].set(500::ms, 0::ms, 1, 500::ms);
	  0.0 => mainOut[i].gain;
	  1 => sub[i].gain;
	  verb => mainRev[i].mix;
  }
}

float partialgain_current[partials];
float partialgain_target[partials];

for (0 => int i; i < voices; i++) 
	for (0 => int j; j < partials; j++){
	0.1 => s[i][j].gain => partialgain_target[j];
	partialgain_target[j] 	=>  partialgain_current[j];
}

// controller boxes
int control[99];

// control events
Event fabON, fabOFF, screenFresh;

// main volume knob
0.0 => float volMain;

1::second => now;

// **** MODULES

spork ~ screenPanel();
spork ~ pitchFab();
spork ~ keys();
spork ~ tweaker();
spork ~ modulator();

for (0 => int partial; partial < 8; partial++)
	spork ~ gainEnv(partial);

spork ~ netComX();
spork ~ netComR();


1::second => now;

fabON.signal(); //turn on on startup

1::day => now; //hang out



// ********* FUNCTIONS ********* FUNCTIONS ********* FUNCTIONS ********* FUNCTIONS 
// #### 
// ####

// **** CREATE PITCH FABRIC
fun void pitchFab()
{

  while (true)
  {
     fabON => now; // start switch

    // create all voices
    for (0 => int i; i < voices; i++)
	  spork ~ buildWave(i, (1. / voices));

    for (0 => int i; i < chanOut; i++)
      1 => e[i].keyOn;

	e[0].attackTime() => now;
  
    fabOFF => now; //stop switch
    
    for (0 => int i; i < chanOut; i++)
      1 => e[i].keyOff;

	e[0].releaseTime() => now;

  }

}


// #### 
// ####


fun void buildWave(int wavNum, float baseGain)
{

  // ## POPULATE ARRAY OF PITCHES (step) **

	baseFundamental * Std.rand2(1,3) => float base;
	0 => int k;
	
	for (1 => int i; i < bases; i++)
	{
		for (0 => int j; j < baseStep; j++)
		{
			base + (j * (((base * baseFactor) - base) / baseStep)) => step[k];
			k++;
		}
		base * baseFactor => base;
	}

  // ## Build Additive Waveforms

  //  * partials - number of components
  //  * wavNum - this waveform (current)
  //  * baseGain - the gain threshold of this stage

   Std.rand2(0, stepMax / 2) => int startStep; // pick any freq from first half
   (stepMax - startStep) / partials => int partInv; // interval size btw partials

  // assign partial freqs, gain, and assign to channel
   for (0 => int i; i < partials; i++)
   { 
	 s[wavNum][i] =< sub[wavNum];
	 s[wavNum][i] => sub[wavNum];
	 step[startStep + (partInv * i)] => s[wavNum][i].freq;
	 (1. / (i + 1)) * baseGain  => s[wavNum][i].gain;
 }

}

// ####
// ####

// modulates freq of all of the oscs a tiny bit, randomized
fun void modulator()
{
  while (true)
  {	
	for (0 => int j; j < voices; j ++)
	{
	  for (0 => int k; k < partials; k++)
		s[j][k].freq() + Std.rand2f(-devi * (k + 1), devi * (k + 1)) 
			=> s[j][k].freq;
	}
	ridgeSize * Std.rand2f(0.9, 1.1)::ms => now;
	screenFresh.signal();
  }
}


// ####
// ####


fun void keys ()
{

 // **** KEYBOARD SETUP

 Hid kb;
 HidMsg msg;
 if( !kb.openKeyboard( 0 ) ) me.exit();
 
 // key numbers
 [53, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 45, 46,
 20, 26, 8, 21, 23, 28, 24, 12, 18, 19, 47, 48, 49,
 4, 22, 7, 9, 10, 11, 13, 14, 15, 51, 52, 
 29, 27, 6, 25, 5, 17, 16, 54, 55, 56, 
 44]
 @=> int key[];
 
 while( true )
 {
    kb => now;

    while( kb.recv(msg) )
    {
		screenFresh.signal(); //trigger for screen refresh

    	for (0 => int i; i < key.cap(); i++)
    	{
    		if ((msg.which == key[i]) && msg.isButtonDown())
    		 1 => control[i];
    		 
    		if (msg.isButtonUp())
    		 0 => control[i];
		 }

		}
	}
}

// ####
// ####



fun void tweaker()
{
	0.001 => float slew;
	while (true)
	{
		// volume controls
		(control[13] * -.2) * slew + volMain => volMain;
		(control[14] * -.1) * slew + volMain => volMain;
		(control[15] * -.05) * slew + volMain => volMain;
		(control[16] * -.01) * slew + volMain => volMain;
		(control[19] * .01) * slew + volMain => volMain;
		(control[20] * .05) * slew + volMain => volMain;
		(control[21] * .1) * slew + volMain => volMain;
		(control[22] * .2) * slew + volMain => volMain;

		// limiter
		if (volMain <= 0) 	
			0  => volMain;
		if (volMain >= .999)
			.999 => volMain;

		// assign volume to all channel gains
		for (0 => int i; i < chanOut; i++)
			volMain => mainOut[i].gain;

		// freq deviation factor

		(control[45] * .005) + devi => devi;
		(control[44] * -.005) + devi => devi;
		if (devi >= 1) 1 => devi;
		if (devi <= 0) 0 => devi;

		
		0 => control[44] => control [45];

        if (control[38]) fabON.signal();
        if (control[37]) fabOFF.signal();

		if (control[32]) 1 => goPulse;
		if (control[29]) 0 => goPulse;

								
		1::ms => now;
	}
}


// ####
// ####

fun void gainEnv(int j)
{
	while (true) {

		Std.rand2f(.0001,.0003) => float bump;
		Std.rand2(10,3000) => int rampTime;

		if (control[27 + j])
		{
			for (0 => int t; t < rampTime / 2; t++)
			{
				for (0 => int i; i < voices; i++)
				{
					s[i][j].gain() + bump => s[i][j].gain;
					if (s[i][j].gain() >= .5) .5 => s[i][j].gain;
				}
				1::ms => now;
			}
			
			for (0 => int t; t < rampTime / 2; t++)
			{
				for (0 => int i; i < voices; i++)
				{
					s[i][j].gain() - bump => s[i][j].gain;
					if (s[i][j].gain() <= .01) .01 => s[i][j].gain;
				}
				1::ms => now;
			}
		}
	1::ms => now;
	}
}	  


// ####
// ####


fun void screenPanel()
{

	while (true) {

		for (0 => int i; i < 40; i++)
			<<< " ", " " >>>;

		<<< "                  !!! F A B R I C S !!!", " " >>>;
		<<< "    ++++++++++++++++++++++++++++++++++++++++++++++++++++", " " >>>;
		<<< " ", " " >>>;
		<<< "                      ", chanOut, " channels">>>;
		<<< "              ", partials, " partials per ", voices, " voices.">>>;
		<<< "              ", baseFundamental, " Hz., ", bases, " bases.">>>;
		<<< "          Base ratio of ", baseFactor, ". ", baseStep, " scale members.">>>;
		<<< " ", " " >>>;
		<<< "         Voices and their first four partials:", " ">>>;
		<<< " ", " " >>>;
		for (0 => int v; v < voices; v++)
				<<<"{", s[v][0].freq(), "} ","{", s[v][1].freq(), "} ","{", s[v][2].freq(), "} ","{", s[v][3].freq(), "} ">>>;
		<<< " ", " " >>>;
		<<< "         Partial Gains for All Voices (0-7):", " ">>>;
		<<< " ", " " >>>;
		<<<"{ ", s[0][0].gain(), " }", "{ ", s[0][1].gain(), " }", "{ ", s[0][2].gain(), " }", "{ ", s[0][3].gain(), " }">>>;
		<<<"{ ", s[0][4].gain(), " }", "{ ", s[0][5].gain(), " }", "{ ", s[0][6].gain(), " }", "{ ", s[0][7].gain(), " }">>>;
		<<< " ", " " >>>;
		<<< "    ++++++++++++++++++++++++++++++++++++++++++++++++++++", " " >>>;
		<<< " ", " " >>>;
		<<< "                ---   --   -  +   ++   +++  (volume)", " " >>>;
		<<< "                [q][w][e][r]  [u][i][o][p] ", "  {", volMain, "}" >>>;
		<<< " ", " " >>>;
		<<< "         partials  0  1  2  3  4  5  6  7     (timbral bumps)", " " >>>;
		<<< "                  [s][d][f][g][h][j][k][l]          ", " ">>>;
		<<< " ", " " >>>;
		<<< "                 on/off             drift", " ">>>;
		<<< "                  -  +              -  + ", " " >>>;
		<<< "                 [z][x]             [,][.] ", " {", devi, "}" >>>;
		<<< " ", " " >>>;
		<<< "         This Hostname: ", Std.getenv("NETNAME"), " " >>>;
		<<< "    ++++++++++++++++++++++++++++++++++++++++++++++++++++", " " >>>;
		<<< " ", " " >>>;

		50::ms => now;
	}
	
}

// ####
// ####

fun void netComX()
{
	//OSC stuff
	OscSend xmit;
	xmit.setHost(serverName, 6449);
	<<<"comx">>>;

	// handshake introduction (machine USER.local here)
	// until answered
	while (call)
	{	
		//send ping
		xmit.startMsg("ping", "s");
		Std.getenv("NETNAME") => xmit.addString;
		1::second => now;
	}
}

// ####
// ####

fun void netComR()
{
	OscRecv recv;
	6448 => recv.port;
	recv.listen();

     // respond to blob messages - types, parameter one, paramter 2
     
     recv.event ("doit, i i f") @=> OscEvent blob;
	
	while (true)
	{
	  blob => now;
	
	  while (blob.nextMsg() != 0)
	  {
	  	blob.getInt() => int job;
	  	blob.getInt() => int p1;
	  	blob.getFloat() => float p2;
	  	
	  	// value of 1 shuts off sound
	    	if (job == 1) 0 => volMain;
	    	
	    	// value of 2 - frequency skips
	    	if (job == 2)
	    	{
	    		for (0 => int cnt; cnt < p1; cnt++)
	    		{
	    			float tmp[voices][partials];
	    			
	    			for (0 => int i; i < voices; i++)
	    			{
	    				for (0 => int j; j < partials; j++)
	    				{
	    					s[i][j].freq() => tmp[i][j];
	    					step[Std.rand2(0, stepMax - 1)] => s[i][j].freq;
    					}
				}
				
				p2 * (1 + Std.rand2f(0, .1))::ms => now;
				
				for (0 => int i; i < voices; i++)
				  for (0 => int j; j < partials; j++)
				    tmp[i][j] => s[i][j].freq;
				
				p2 * (1 + Std.rand2f(0, .1))::ms => now;

			}
		}
		
		// value of 3 - ridge size change
	    	if (job == 3)
	    	{
	    		p1 => ridgeSize;
		}
		
		// value of 4 - freq deviation change
	    	if (job == 4)
	    	{
	    		p2 => devi;
    		}
    		
    		// value of 4 - freq deviation change
	    	if (job == 5)
	    	{
	    		p2 => volMain;
    		}


	    	
    	  }
     }

}




// ####  for testing below
// ####

fun void freqShow() //feedback for oscillators freqs
{
	while (true) {
		for (0 => int i; i < voices; i++)
		  for (0 => int j; j < partials; j++)
	<<<"Voice ", i, " - Partial ", j, " - Frequency ", s[i][j].freq()>>>;
		1000::ms => now;
	}
}

// ####
// ####

fun void gainShow() //feedback for gains
{
  while (true)
  {
    for (0 => int i; i < chanOut; i++)
    	<<<"Main Vol ", i, " - ", mainOut[i].gain()>>>;
    1000::ms => now;
  }
}

fun void freqTest()
{

	4::second => now;
	
	for (0 => int cnt; cnt < Std.rand2(6, 12); cnt++)
	{
		Std.rand2(10,40)::ms => now;
		float tmp[voices][partials];
		
		for (0 => int i; i < voices; i++)
		{
			for (0 => int j; j < partials; j++)
			{
				s[i][j].freq() => tmp[i][j];
				step[Std.rand2(0, stepMax - 1)] => s[i][j].freq;
			}
		}
		Std.rand2(10,50)::ms => now;
	
		for (0 => int i; i < voices; i++)
		  for (0 => int j; j < partials; j++)
			tmp[i][j] => s[i][j].freq;
	}
	
}
