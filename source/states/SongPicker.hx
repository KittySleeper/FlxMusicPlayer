package states;

import flixel.addons.ui.FlxButtonPlus;

class SongPicker extends FlxState {
    override function create() {
        super.create();

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
    }
}