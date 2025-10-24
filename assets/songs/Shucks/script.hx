var video;

function create() {
    video = new FlxVideoSprite(0, 0);
    video.antialiasing = true;
    video.bitmap.onEndReached.add(video.destroy);
    video.load("assets/videos/shucks.mp4");
    add(video);
}

function playEvent(e) {
    switch (e.name) {
        case "shuckscene":
            video.play();
        case "shucks":
            
    }
}