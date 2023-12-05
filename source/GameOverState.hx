package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.sound.FlxSound;
import flixel.FlxSprite;

class GameOverState extends MusicBeatSubstate {
	var kevin:FlxSprite;

	override function create() {
		kevin = new FlxSprite();
		kevin.frames = Paths.getSparrowAtlas("kevin", null);
		kevin.animation.addByPrefix("kevin", "kevin", 24, false);
		kevin.animation.play("kevin");
		kevin.scale.set(5, 5);
		kevin.screenCenter();
		add(kevin);

		var music:FlxSound = new FlxSound();
		music.loadEmbedded(Paths.music('whistle'), false, true);
		music.volume = 0.6;
		music.play();

		FlxG.sound.list.add(music);

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (kevin.animation.finished)
			FlxG.switchState(new PlayState());
	}
}
