package objects;

import flixel.group.FlxSpriteGroup;
import lime.media.AudioSource;

class Visualizer extends FlxTypedSpriteGroup<FlxSprite>
{
    var grpBars:FlxTypedSpriteGroup<FlxSprite>;
    var peakLines:FlxTypedSpriteGroup<FlxSprite>;
    var analyzer:funkin.vis.dsp.SpectralAnalyzer;

    public function new(audioSource:AudioSource, barCount:Int = 16)
    {
        super();

        analyzer = new funkin.vis.dsp.SpectralAnalyzer(audioSource, barCount, 0.1, 10);

        grpBars = new FlxTypedSpriteGroup<FlxSprite>();
		add(grpBars);

        peakLines = new FlxTypedSpriteGroup<FlxSprite>();
        if (OptionsState.options.get("Show Peaks")) add(peakLines);

		for (i in 0...barCount)
		{
			var spr = new FlxSprite((i / barCount) * FlxG.width, 0).makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, FlxG.height);
            spr.origin.set(0, FlxG.height);
			grpBars.add(spr);

            spr = new FlxSprite((i / barCount) * FlxG.width, 0).makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, 1);
            peakLines.add(spr);
		}
    }

    @:generic
    static inline function min<T:Float>(x:T, y:T):T
    {
        return x > y ? y : x;
    }

    var smoothVolume:Float = 1;

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        smoothVolume = FlxMath.lerp(smoothVolume, flixel.FlxG.sound.muted ? 0 : flixel.FlxG.sound.volume, 0.6 * elapsed * 60);

        var levels = analyzer.getLevels();

        for (i in 0...min(grpBars.members.length, levels.length)) {
            grpBars.members[i].scale.y = levels[i].value * smoothVolume;
            peakLines.members[i].y = FlxG.height - (levels[i].peak * smoothVolume * FlxG.height);
        }
    }
}