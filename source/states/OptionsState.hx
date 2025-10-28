package states;

import flixel.addons.ui.FlxUICheckBox;

class OptionsState extends FlxState {
    public static var options:Map<String, Dynamic> = ["Show Peaks" => true, "Camera Bops On Beat" => true, "Shuffle Mode" => false]; //make this use more than bools eventually.

    override public function create() {
        super.create();

        var i:Int = -1;

        for (key => value in options) {
            i++;

            var checkBox:FlxUICheckBox;
            checkBox = new FlxUICheckBox(0, i * 30, null, null, key, 200, [], function() {
                options.set(key, checkBox.checked);
                FlxG.save.data.options.set(key, checkBox.checked);
                FlxG.save.flush();
            });
            checkBox.checked = value;
            add(checkBox);
        }
    }

    override public function update(elapsed) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE) FlxG.switchState(new SongPickerState());
    }

    public static function initOptions() {
        var fuckyou:Map<String, Dynamic> = cast FlxG.save.data.options;

        if (fuckyou == null) {
            FlxG.save.data.options = options;
		} else {
            for (option => value in fuckyou)
				 options.set(option, value);
		}

        FlxG.save.flush();
    }
}