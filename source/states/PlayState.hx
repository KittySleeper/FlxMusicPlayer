package states;

import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
import haxe.Json;
import lime.media.AudioSource;
import sys.FileSystem;
import flixel.tweens.FlxEase;

class PlayState extends FlxState
{
	var lastBeat:Float = -1;
	var songPos:Float = 0;
	var curBeat:Float = 0;

	public static var curSongIndex:Int = 0;
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

	var camBopIntensity:Float = .15;
	var camBopLerpSpeed:Float = 0.1;
	var camBopBeat:Float = 4;

	var uiBottom:FlxSprite;

	override public function create()
	{
		super.create();

		uiCam = FlxG.cameras.add(new FlxCamera(), false);
		uiCam.bgColor = 0;
		uiCam.alpha = 0.75;

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

		var songFolder = "songs/" + Main.songList[index];

		songData = Paths.json('$songFolder/meta');
		songEvents = Paths.exists('$songFolder/events.json') ? Paths.json('$songFolder/events').events : [];

		script = new HScript(songFolder + "/script");
		if (!script.isBlank && script.expr != null) {
			script.interp.scriptObject = this;
			script.interp.execute(script.expr);
		}

		script.callFunction("create");

		FlxG.sound.playMusic(Paths.song('$songFolder/music'));

		FlxG.sound.music.volume = 0;
		FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.75, {ease: FlxEase.quadOut});

		FlxG.sound.music.onComplete = function() {
			curSongIndex++;

			if (curSongIndex >= Main.songList.length)
				curSongIndex = 0;

			loadSong(curSongIndex);
		};

		@:privateAccess
		var musicSource:AudioSource = cast FlxG.sound.music._channel.__source;

		visualizer = new Visualizer(musicSource, 35);
		visualizer.color = FlxColor.fromString(songData.songColor);
		visualizer.alpha = 0.45;
		add(visualizer);

		uiBottom = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, FlxColor.GRAY);
		uiBottom.y = FlxG.height - uiBottom.height;

		albumCover = new FlxSprite(5, 0, Paths.bitmap('$songFolder/cover'));
		albumCover.setGraphicSize(95, 95);
		albumCover.updateHitbox();
		albumCover.y = ((uiBottom.height - albumCover.height) / 2) + uiBottom.y;

		songText = new FlxText(albumCover.x + 100, 0, 0, songData.name + "\n" + songData.artist, 16);
		songText.y = ((uiBottom.height - songText.height) / 2) + uiBottom.y;
		songText.setFormat(Paths.rawfile("fonts/comic.ttf"), 20, FlxColor.BLACK, LEFT);

		songPosBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 450, 30, this, "songPos", 0, FlxG.sound.music.length / 1000);
		songPosBar.numDivisions = 1200;
		songPosBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		songPosBar.color = FlxColor.fromString(songData.songColor);
		songPosBar.y = ((uiBottom.height - songPosBar.height) / 2) + uiBottom.y;
		songPosBar.screenCenter(X);

		songTimeText = new FlxText(songPosBar.x - 50, songPosBar.y, songPosBar.width, "0:00", 16);
		songTimeText.setFormat(Paths.rawfile("fonts/comic.ttf"), 20, FlxColor.BLACK, LEFT);

		songLengthText = new FlxText(songPosBar.x + 50, songPosBar.y, songPosBar.width, "0:00", 16);
		songLengthText.setFormat(Paths.rawfile("fonts/comic.ttf"), 20, FlxColor.BLACK, RIGHT);

		play = new FlxSprite(0, songPosBar.y + 35).loadGraphic(Paths.bitmap("images/play"), true, 16, 16);
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

		script.callFunction("postCreate");
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE) FlxG.switchState(new SongPicker());
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

			if (!FlxG.sound.music.playing) return;
		}

		super.update(elapsed);

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, camBopLerpSpeed * elapsed * 60);

		script.callFunction("update", [elapsed]);
	}

	function beatHit()
	{
		if (lastBeat % camBopBeat == 0)
			FlxG.camera.zoom += camBopIntensity;

		script.callFunction("beatHit");
	}

	function playEvent(e:Dynamic) {
		switch (e.name) {
			case "BPM Change":
				songData.bpm = e.params[0];
			case "Cam Bop Change":
				camBopBeat = e.params[0];
				camBopIntensity = e.params[1];
				camBopLerpSpeed = e.params[2];
			default:
				//fuck me in the ass please :3
		}

		script.callFunction("playEvent", [e]);
	}
}
