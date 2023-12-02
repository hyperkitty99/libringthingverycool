package openfl.display;

import flixel.util.FlxStringUtil;
import openfl.Lib;
import flixel.FlxG;
import flixel.util.FlxColor;
import lime.system.System;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;

class FPS extends Sprite {
	public var currentFPS(default, null):Int;

	private var normalColor:FlxColor = 0xFFFFFFFF;
	private var outlineColor:FlxColor = 0xFF000000;
	public var baseText:TextField;
	public var outlineTexts:Array<TextField> = [];
	private var outlineWidth:Int = 4;
	private var outlineQuality:Int = 16;
	var defaultTextFormat:TextFormat;

	public var text(default, set):String; 

	public function new(x:Float = 10, y:Float = 10) {
		super();

		this.x = x;
		this.y = y;

		this.defaultTextFormat = new TextFormat(Paths.font("DIN2014Bold.ttf"), 20, normalColor);

		baseText = new TextField();
		baseText.defaultTextFormat = this.defaultTextFormat;
		baseText.selectable = false;
		baseText.mouseEnabled = false;
		baseText.width = FlxG.width;

		currentFPS = -2147483647;

		for (i in 0...outlineQuality) {
			var otext:TextField = new TextField();
			otext.x = Math.sin(i) * outlineWidth;
			otext.y = Math.cos(i) * outlineWidth;
			otext.defaultTextFormat = this.defaultTextFormat;
			otext.textColor = outlineColor;
			otext.width = baseText.width;
			outlineTexts.push(otext);
			addChild(otext);
		}

		addChild(baseText);

		text = 'FPS: ${currentFPS}';
		baseText.textColor = normalColor;
	}

	private function set_text(value:String):String {
		baseText.text = value;
		for (text in outlineTexts)
			text.text = value;

		return value;
	}
}
