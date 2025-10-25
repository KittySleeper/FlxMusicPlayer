var video;

function create() {
    video = new FlxVideoSprite(0, 0);
    video.antialiasing = true;
    video.bitmap.onEndReached.add(video.destroy);
    video.load("assets/videos/shucks.mp4");
    add(video);
}

function postCreate() {
    var customFont = Paths.rawfile("fonts/SuperMario256.ttf");
    
    songText.font = customFont;
    songTimeText.font = customFont;
    songLengthText.font = customFont;

    var text = new FlxSprite();
    text.frames = Paths.sparrowAtlas('images/ShucksText');
    text.animation.addByPrefix('text', "Shucks", 24);
    text.animation.play('text');
    text.antialiasing = false;
    text.visible = false;
    text.screenCenter();
    add(text);
}

function playEvent(e) {
    switch (e.name) {
        case "shuckscene":
            trace("test");
            video.play();
        case "shucks!":
            text.visible = true;
            FlxTween.tween(text, {alpha: 0}, 4.5, {ease: FlxEase.cubeInOut});
    }
}