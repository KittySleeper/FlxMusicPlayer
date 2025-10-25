package backend;

import haxe.Json;
import openfl.media.Sound;
import openfl.display.BitmapData;

import sys.io.File;
import sys.FileSystem;

import flixel.graphics.frames.FlxAtlasFrames;

class Paths {
    public static inline function song(path:String = "") return Sound.fromFile("assets/" + path + ".ogg");
    public static inline function bitmap(path:String = "") return BitmapData.fromFile("assets/" + path + ".png");
    public static inline function sparrowAtlas(path:String) return FlxAtlasFrames.fromSparrow(bitmap(path), file(path + ".xml"));
    public static inline function json(path:String) return Json.parse(file(path + ".json"));
    public static inline function file(path:String) return File.getContent("assets/" + path);
    public static inline function rawfile(path:String) return 'assets/$path';

    public static inline function exists(path:String) return FileSystem.exists("./assets/" + path);
}