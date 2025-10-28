package states;

import flixel.addons.ui.FlxButtonPlus;

class SongPickerState extends FlxState {
    override function create() {
        super.create();
        OptionsState.initOptions();

        for (i => song in Main.songList) {
            var button:FlxButtonPlus = new FlxButtonPlus(0, 0, function() {
                PlayState.curSongIndex = i;
                FlxG.switchState(new PlayState());
            }, song, 650, 35);
            button.screenCenter();
            button.y += i * 40;
            add(button);
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.CONTROL) FlxG.switchState(new OptionsState());
    }
}