package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var songList:Array<String> = [];

	public function new()
	{
		super();

		songList = sys.FileSystem.readDirectory("./assets/songs/");

		HScript.parser = new hscript.Parser();
		HScript.parser.allowJSON = true;
		HScript.parser.allowMetadata = true;
		HScript.parser.allowTypes = true;
		HScript.parser.preprocesorValues = [
			"desktop" => #if (desktop) true #else false #end,
			"windows" => #if (windows) true #else false #end,
			"mac" => #if (mac) true #else false #end,
			"linux" => #if (linux) true #else false #end,
			"debugBuild" => #if (debug) true #else false #end
		];

		var game = addChild(new FlxGame(0, 0, PlayState, 250, 250, true));
		flixel.FlxG.autoPause = false;
	}
}
