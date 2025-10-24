package;

import sys.io.File;
import flixel.util.FlxTimer;
import hxvlc.flixel.FlxVideoSprite;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import haxe.Json;
import openfl.Assets;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import lime.media.AudioSource;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.media.Sound;
import openfl.display.BitmapData;

class PlayState extends FlxState
{
	var lastBeat:Float = -1;
	var songPos:Float = 0;
	var curBeat:Float = 0;

	var songList:Array<String> = [];
	var curSongIndex:Int = 0;
	var songData:Dynamic;
	var songEvents:Array<Dynamic>;

	var script:HScript;

	var uiCam:FlxCamera;

	var visualizer:Visualizer;
	var albumCover:FlxSprite;
	var songText:FlxText;
	var songLengthText:FlxText;
	var songTimeText:FlxText;
	var songPosBar:FlxBar;
	var play:FlxSprite;

	var uiBottom:FlxSprite;

	override public function create()
	{
		super.create();

		uiCam = FlxG.cameras.add(new FlxCamera(), false);
		uiCam.bgColor = 0;
		uiCam.alpha = 0.75;

		songList = FileSystem.readDirectory("./assets/songs/").filter(f -> FileSystem.isDirectory("./assets/songs/" + f));

		loadSong(curSongIndex);
	}

	function loadSong(index:Int)
	{
		// Stop and remove previous stuff
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		lastBeat = -1;
		curBeat = 0;
		songPos = 0;

		for (obj in [visualizer, uiBottom, albumCover, songText, songPosBar, songTimeText, songLengthText, play]) {
			if (obj != null) {
				remove(obj, true);
				obj.destroy();
			}
		}

		var songFolder = "assets/songs/" + songList[index] + "/";
		songData = Json.parse(File.getContent(songFolder + "meta.json"));
		songEvents = FileSystem.exists("./" + songFolder + "events.json") ? Json.parse(File.getContent(songFolder + "events.json")).events : [];

		script = new HScript(songFolder + "script");
		if (!script.isBlank && script.expr != null) {
			script.interp.scriptObject = this;
			script.interp.execute(script.expr);
		}

		script.callFunction("create");

		var epicSong = Sound.fromFile(songFolder + "music.ogg");
		var epicSongCover = BitmapData.fromFile(songFolder + "cover.png");

		FlxG.sound.playMusic(epicSong);

		FlxG.sound.music.volume = 0;
		FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.75, {ease: FlxEase.quadOut});

		FlxG.sound.music.onComplete = function() {
			curSongIndex++;

			if (curSongIndex >= songList.length)
				curSongIndex = 0;

			loadSong(curSongIndex);
		};

		@:privateAccess
		var musicSource:AudioSource = cast FlxG.sound.music._channel.__source;

		visualizer = new Visualizer(musicSource, 35, FlxColor.fromString(songData.songColor));
		visualizer.alpha = 0.45;
		add(visualizer);

		uiBottom = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, FlxColor.GRAY);
		uiBottom.y = FlxG.height - uiBottom.height;

		albumCover = new FlxSprite(5, 0, epicSongCover);
		albumCover.setGraphicSize(95, 95);
		albumCover.updateHitbox();
		albumCover.y = ((uiBottom.height - albumCover.height) / 2) + uiBottom.y;

		songText = new FlxText(albumCover.x + 100, 0, 0, songData.name + "\n" + songData.artist, 16);
		songText.y = ((uiBottom.height - songText.height) / 2) + uiBottom.y;
		songText.setFormat("assets/fonts/comic.ttf", 20, FlxColor.BLACK, LEFT);

		songPosBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 450, 30, this, "songPos", 0, FlxG.sound.music.length / 1000);
		songPosBar.numDivisions = 1200;
		songPosBar.y = ((uiBottom.height - songPosBar.height) / 2) + uiBottom.y;
		songPosBar.screenCenter(X);

		songTimeText = new FlxText(songPosBar.x - 50, songPosBar.y, songPosBar.width, "0:00", 16);
		songTimeText.setFormat("assets/fonts/comic.ttf", 20, FlxColor.BLACK, LEFT);

		songLengthText = new FlxText(songPosBar.x + 50, songPosBar.y, songPosBar.width, "0:00", 16);
		songLengthText.setFormat("assets/fonts/comic.ttf", 20, FlxColor.BLACK, RIGHT);

		play = new FlxSprite(0, songPosBar.y + 35).loadGraphic("assets/images/play.png", true, 16, 16);
		play.setGraphicSize(Std.int(play.width * 1.65));
		play.updateHitbox();
		play.animation.add("play", [0], 1, false);
		play.animation.add("pause", [1], 1, false);
		play.animation.play("play");
		play.screenCenter(X);

		for (obj in [uiBottom, albumCover, songText, songPosBar, songTimeText, songLengthText, play])
		{
			obj.camera = uiCam;
			obj.antialiasing = false;
			add(obj);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, 0.1 * elapsed * 60);

		if (FlxG.sound.music != null) {
			songPos = FlxG.sound.music.time / 1000;
			curBeat = (songPos * songData.bpm) / 60;

			if (Math.floor(curBeat) > lastBeat || Math.floor(curBeat) < lastBeat) {
				lastBeat = Math.floor((FlxG.sound.music.time / 1000) * songData.bpm / 60);
				beatHit();
			}
			
			for (event in songEvents) {
				if (songPos > event.time) {
					playEvent(event);
					songEvents.remove(event);
				}
			}

			if (FlxG.keys.justPressed.SPACE || (FlxG.mouse.overlaps(play) && FlxG.mouse.justPressed)) {
				if (FlxG.sound.music.playing) {
					FlxG.sound.music.pause();
					play.animation.play("pause");
				} else {
					FlxG.sound.music.resume();
					play.animation.play("play");
				}
			}

			if (FlxG.keys.pressed.ALT ? FlxG.keys.pressed.LEFT : FlxG.keys.justPressed.LEFT) {
				if (FlxG.keys.pressed.CONTROL)
					FlxG.timeScale = FlxG.sound.music.pitch -= 0.005;
				else
					FlxG.sound.music.time -= 500;
			}

			if (FlxG.keys.pressed.ALT ? FlxG.keys.pressed.RIGHT : FlxG.keys.justPressed.RIGHT) {
				if (FlxG.keys.pressed.CONTROL)
					FlxG.timeScale = FlxG.sound.music.pitch += 0.005;
				else
					FlxG.sound.music.time += 500;
			}

			songTimeText.text = FlxStringUtil.formatTime(songPos);
			songLengthText.text = FlxStringUtil.formatTime(FlxG.sound.music.length / 1000);
		}

		script.callFunction("update", [elapsed]);
	}

	function beatHit()
	{
		if (lastBeat % 4 == 0)
			FlxG.camera.zoom += 0.15;

		script.callFunction("beatHit");
	}

	function playEvent(e:Dynamic) {
		switch (e.name) {
			default:
				//fuck me in the ass please :3
		}

		script.callFunction("playEvent", [e]);
	}
}
