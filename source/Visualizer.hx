package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import lime.media.AudioSource;

class Visualizer extends FlxTypedSpriteGroup<FlxSprite>
{
    var grpBars:FlxTypedSpriteGroup<FlxSprite>;
    var peakLines:FlxTypedSpriteGroup<FlxSprite>;
    var analyzer:funkin.vis.dsp.SpectralAnalyzer;

    public function new(audioSource:AudioSource, barCount:Int = 16, barColor:FlxColor = FlxColor.RED)
    {
        super();

        analyzer = new funkin.vis.dsp.SpectralAnalyzer(audioSource, barCount, 0.1, 10);

        grpBars = new FlxTypedSpriteGroup<FlxSprite>();
		add(grpBars);

        peakLines = new FlxTypedSpriteGroup<FlxSprite>();
        add(peakLines);

		for (i in 0...barCount)
		{
			var spr = new FlxSprite((i / barCount) * FlxG.width, 0).makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, FlxG.height, barColor);
            spr.origin.set(0, FlxG.height);
			grpBars.add(spr);

            spr = new FlxSprite((i / barCount) * FlxG.width, 0).makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, 1, barColor);
            peakLines.add(spr);
		}
    }

    @:generic
    static inline function min<T:Float>(x:T, y:T):T
    {
        return x > y ? y : x;
    }

    override function draw()
    {
        var levels = analyzer.getLevels();

        for (i in 0...min(grpBars.members.length, levels.length)) {
            grpBars.members[i].scale.y = flixel.FlxG.sound.muted ? 0 : levels[i].value * flixel.FlxG.sound.volume;
            peakLines.members[i].y = flixel.FlxG.sound.muted ? 0 : FlxG.height - (levels[i].peak * flixel.FlxG.sound.volume * FlxG.height);
        }

        super.draw();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
    }
}