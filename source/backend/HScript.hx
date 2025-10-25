package backend;

import sys.io.File;
import hscript.Expr.Error;
import openfl.Assets;
import sys.FileSystem;
import hscript.*;

using StringTools;

class HScript {
	public static final allowedExtensions:Array<String> = ["hx", "hscript", "hxs"];
	public static var parser:Parser;
	public static var staticVars:Map<String, Dynamic> = new Map();

	public var interp:Interp;
	public var expr:Expr;

	var initialLine:Int = 0;

	public var isBlank:Bool;

	var blankVars:Map<String, Null<Dynamic>>;
	var path:String;

	public function new(scriptPath:String) {		
		path = scriptPath;

		var boolArray:Array<Bool> = [for (ext in allowedExtensions) Paths.exists('$scriptPath.$ext')];

		isBlank = (!boolArray.contains(true));

		if (boolArray.contains(true)) {
			interp = new Interp();
			interp.staticVariables = staticVars;
			interp.allowStaticVariables = true;
			interp.allowPublicVariables = true;
			interp.errorHandler = traceError;
			try {
				var path = scriptPath + "." + allowedExtensions[boolArray.indexOf(true)];
				parser.line = 1; // Reset the parser position.
				expr = parser.parseString(Paths.file(path));
				interp.variables.set("trace", hscriptTrace);
			} catch (e) {
				lime.app.Application.current.window.alert('Looks like the game couldn\'t parse your hscript file.\n$scriptPath\n${e.toString()}\n\nThe game will replace this\nscript with a blank script.',
					'Failed to Parse $scriptPath');
				isBlank = true;
			}
		}
		if (isBlank) {
			blankVars = new Map();
		} else {
			var defaultVars:Map<String, Dynamic> = [
				"Math" => Math,
				"Std" => Std,

				"FlxG" => flixel.FlxG,
				"FlxSprite" => flixel.FlxSprite,
				"FlxText" => flixel.text.FlxText,

				// Abstract Imports
				"FlxColor" => Type.resolveClass("flixel.util.FlxColor.FlxColor_HSC"),

				// Flixel Addons because hscript says "FUCK YOU! I AINT IMPORTING ADDONS!"
				"FlxTrail" => flixel.addons.effects.FlxTrail,
				"FlxBackdrop" => flixel.addons.display.FlxBackdrop,

				"FlxTween" => flixel.tweens.FlxTween,
				"FlxEase" => flixel.tweens.FlxEase,

				"FlxVideoSprite" => hxvlc.flixel.FlxVideoSprite,
				"FlxTimer" => flixel.util.FlxTimer,

				"Assets" => Assets,
				"Paths" => Paths
			];
			for (va in defaultVars.keys())
				setValue(va, defaultVars[va]);
		}
	}

	function hscriptTrace(v:Dynamic)
		trace(path + ":" + interp.posInfos().lineNumber + ": " + Std.string(v));

	function traceError(e:Error) {
		trace(path + " " + e);
	}

	public function callFunction(name:String, ?params:Array<Dynamic>) {
		if (interp == null || parser == null)
			return null;

		var functionVar = (isBlank) ? blankVars.get(name) : interp.variables.get(name);
		var hasParams = (params != null && params.length > 0);
		if (functionVar == null || !Reflect.isFunction(functionVar))
			return null;
		return hasParams ? Reflect.callMethod(null, functionVar, params) : functionVar();
	}

	inline public function getValue(name:String)
		return (isBlank) ? blankVars.get(name) : (interp != null) ? interp.variables.get(name) : null;

	inline public function setValue(name:String, value:Dynamic)
		(isBlank) ? blankVars.set(name, value) : (interp != null) ? interp.variables.set(name, value) : null;
}
