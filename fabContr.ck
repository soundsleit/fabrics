// ********************************** //
// FabContr [fabContr.ck] v. 3.0
// April 08 - Jan 09
// Updated, Sept. 2015
// 
// A server controller for fabrics instruments
//
// by Scott Smallwood


// array for machine station names
string name[50];

// machine counter
0 => int machine;
string lastMachine, checkMachine;

// initializations
1600 => int pulse;
7 => int skipNum;
10 => int skipLen;

// controls
int control[99];
Event screenFresh;

OscSend xmit;

spork ~ rollCall();
spork ~ keys();
spork ~ instants();
spork ~ skipper();
spork ~ skipMods();
spork ~ onOFF();
spork ~ screenPanel();

while (true) 1::second => now;


fun void rollCall()
{

	OscRecv recv;
	6449 => recv.port;
	recv.listen();


	// wait for ping from new machine
	recv.event( "ping, s" ) @=> OscEvent oe;

	// add new machine name to cluster array
	while (true)
	{
		0 => int alreadyGotit;
		oe => now;
		while (oe.nextMsg() != 0)
		{
			oe.getString() => checkMachine;
			for (0 => int i; i < machine; i++)
				if (checkMachine == name[i]) 1 => alreadyGotit;
			
			if (!alreadyGotit) {
				checkMachine => lastMachine => name[machine];
				xmit.setHost(name[machine], 6448);
				xmit.startMsg("ok", "i");
				1 => xmit.addInt;
				machine++;
				screenFresh.signal();
			}
		}
	}
}


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
		screenFresh.signal();

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

fun void instants()
{
	while (true)
	{
		// ridgeSize change to min
		if (control[7])
		{
			for (0 => int i; i < machine; i++)
			{
				xmit.setHost(name[i], 6448);
				xmit.startMsg("doit", "i i f");
				3 => xmit.addInt;
				20 => xmit.addInt;
				0 => xmit.addFloat;
				0 => control[7];
			}
		}
		
		// ridgeSize change to max
		if (control[8])
		{
			for (0 => int i; i < machine; i++)
			{
				xmit.setHost(name[i], 6448);
				xmit.startMsg("doit", "i i f");
				3 => xmit.addInt;
				100 => xmit.addInt;
				0 => xmit.addFloat;
				0 => control[8];
			}
		}
		
		// deviation change to min
		if (control[9])
		{
			for (0 => int i; i < machine; i++)
			{
				xmit.setHost(name[i], 6448);
				xmit.startMsg("doit", "i i f");
				4 => xmit.addInt;
				0 => xmit.addInt;
				0 => xmit.addFloat;
				0 => control[9];
			}
		}
		
		// deviation change to max
		if (control[10])
		{
			for (0 => int i; i < machine; i++)
			{
				xmit.setHost(name[i], 6448);
				xmit.startMsg("doit", "i i f");
				4 => xmit.addInt;
				0 => xmit.addInt;
				.005 => xmit.addFloat;
				0 => control[10];
			}
		}


		100::ms => now;
	}
}	

fun void onOFF ()
{
	while (true)
	{
		// vol down to 0
		if (control[23])
		{
			for (0 => int i; i < machine; i++)
			{
				xmit.setHost(name[i], 6448);
				xmit.startMsg("doit", "i i f");
				5 => xmit.addInt;
				0 => xmit.addInt;
				0 => xmit.addFloat;
				0 => control[23];
			}
		}
		
		// vol up to .5
		if (control[24])
		{
			for (0 => int i; i < machine; i++)
			{
				xmit.setHost(name[i], 6448);
				xmit.startMsg("doit", "i i f");
				5 => xmit.addInt;
				0 => xmit.addInt;
				.2 => xmit.addFloat;
				0 => control[24];
			}
		}
		5::ms => now;
	}
}

fun void skipper() 
{

	while (true)
	{	
		if (control[12])
		{
			spork ~ freqSkip();
			0 => control[12];
		}
			
		100::ms => now;
	}
}

fun void freqSkip()
{
			
	while (true)
	{
		for (0 => int i; i < machine; i++)
		{
			xmit.setHost(name[i], 6448);
			xmit.startMsg("doit", "i i f");
			2 => xmit.addInt;
			skipNum => xmit.addInt;
			skipLen $ float => xmit.addFloat;
		}
		pulse::ms => now;
		break;
	}
}


fun void skipMods()
{

	while (true)
	{
		skipNum - control[1] => skipNum;
		skipNum + control[2] => skipNum;
		
		skipLen - control[3] => skipLen;
		skipLen + control[4] => skipLen;
		
		if (skipLen <= 10) 10 => skipLen;
		if (skipNum <= 1) 1 => skipNum;

		pulse - (10 * control[5]) => pulse;
		pulse + (10 * control[6]) => pulse;
		
		100::ms => now;
	}
}


fun void screenPanel()
{

	while (true)
	{
		for (0 => int i; i < 40; i++)
			<<< " ", " " >>>;
		<<< " ", " " >>>;
		<<< " ", " " >>>;
		<<< "              Fabric Server Control", " " >>>;
		<<< "<> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <>", " " >>>;
		<<< " ", " " >>>;
		<<< "   :: CONTROLS ::", " " >>>;
		<<< " skips     size          ridges  devi       SKIP", " " >>>;
		<<< " -   +     -   +         -   +   0 .005      '  ", " " >>>;
		<<< "[1] [2]   [3] [4]       [7] [8] [9] [0] [-] [=] ", " " >>>;
		<<< "{ ", skipNum, " }", "  { ", skipLen, " }" >>>;
		<<< "                         silence all instruments", " " >>>;
		<<< "                         (0, or .5)       -   +", " " >>>;
		<<< "                                         [{] [}] ", " " >>>;
		<<< " Last player: ", lastMachine, " " >>>;
		<<< " Total players: ", machine, " " >>>;
		<<< " ", " " >>>;
		<<< "<> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <>", " " >>>;
		<<< " ", " " >>>;

		screenFresh => now;
	}
}
