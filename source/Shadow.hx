package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxCamera;

class Shadow extends FlxSkewedSprite {
	public var dMulti:Float = 1;
    public var isLeftS:Bool = true;

	public function new(X:Float = 0, Y:Float = 0, ?image:String, ?desY:Float = 0, ?depth = 1, ?isLeft:Bool = true) {
		super(X, Y);

		loadGraphic(Paths.image(image));
		updateHitbox();
		offset.set(width / 2, height / 2 + desY);
        origin.set(0, 0);
		dMulti = depth;
        isLeftS = isLeft;

		antialiasing = true;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

        if (isLeftS)
	    	skew.x = -(PlayState.camFollowPos.x - x) / (20 / dMulti);
        else
            skew.x = -(PlayState.camFollowPos.x - 1500) / (20 / dMulti);
		// scale.y = -(PlayState.camFollowPos.y - y - height) / (500 / dMulti);
	}

	override public function isOnScreen(?camera:FlxCamera):Bool {
        return true;
    }
}