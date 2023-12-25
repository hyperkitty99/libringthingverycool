package;

import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import Song;

using StringTools;

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData {
	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:PlayState.SwagSong) {
		var stage:String = '';
		if(SONG.stage != null)
			stage = SONG.stage;

		var stageFile:StageFile = getStageFile(stage);
		if(stageFile == null)
			forceNextDirectory = '';
		else
			forceNextDirectory = stageFile.directory;

	}

	public static function getStageFile(stage:String):StageFile {
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('data/' + stage + '.json');

		if(Assets.exists(path))
			rawJson = Assets.getText(path);
		else
			return null;

		return cast Json.parse(rawJson);
	}
}