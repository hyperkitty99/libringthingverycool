package;

#if (hl && hlvideo)

import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import hl.video.Webm;
import hl.video.Aom;
import openfl.display3D.textures.RectangleTexture;
import flixel.FlxG;
import haxe.io.Bytes;

enum FrameState {
	Free;
	Loading;
	Ready;
	Ended;
}

typedef Frame = {
	var pixels : BitmapData;
	var state : FrameState;
	var time : Float;
}

class FrameCache {
	var frames : Array<Frame> = [];
	var readCursor = 0;
	var writeCursor = 0;
	var width : Int;
	var height : Int;

	public function new(size : Int, w : Int, h : Int) {
		width = w;
		height = h;
		frames = [];
		for(i in 0 ... size) {
			frames[i] = {
				pixels: new BitmapData(w, h),
				state: Free,
				time: 0
			}
		}
	}

	public function currentFrame():Frame {
		if( frames == null )
			return null;
		return frames[readCursor];
	}

	public function nextFrame():Bool {
		var nextCursor = (readCursor + 1) % frames.length;
		frames[readCursor].state = Free;
		readCursor = nextCursor;
		return true;
	}

	function frameBufferSize() {
		if(writeCursor < readCursor)
			return frames.length - readCursor + writeCursor;
		else
			return writeCursor - readCursor;
	}

	public function isFull() {
		if(writeCursor < readCursor)
			return frames.length - readCursor + writeCursor >= frames.length - 1;
		else
			return writeCursor - readCursor >= frames.length - 1;
	}

	public function isEmpty() {
		return readCursor == writeCursor;
	}

	public function prepareFrame(webm:hl.video.Webm, codec:hl.video.Aom.Codec, loop:Bool):Frame {
		if(frames[writeCursor].state != Free)
			return null;

		var savedCursor = writeCursor;
		var f = frames[writeCursor];

		var time = webm.readFrame(codec, f.pixels.getPixels(f.pixels.rect));
		if(time == null) {
			if(loop) {
				webm.rewind();
				time = webm.readFrame(codec, f.pixels.getPixels(f.pixels.rect));
			}
			else {
				f.time = 0;
				f.state = Ended;
				return f;
			}
		}
		f.time = time;
		f.state = Ready;
		writeCursor++;
		if(writeCursor >= frames.length)
			writeCursor %= frames.length;
		return f;
	}

	public function dispose() {
		for(f in frames)
			f.pixels.dispose();
	}
}

class Video extends FlxSprite {

	var webm : hl.video.Webm;
	var codec : hl.video.Aom.Codec;
	var multithread : Bool;
	var cache : FrameCache;
	var frameCacheSize : Int = 1;
	var stopThread = false;
	var texture:RectangleTexture;
	var playTime : Float;
	var videoTime : Float;
	var frameReady : Bool;
	var loopVideo : Bool;

	public var videoWidth(default, null) : Int;
	public var videoHeight(default, null) : Int;
	public var playing : Bool;
	public var time(get, null) : Float;
	public var loop(get, set) : Bool;

	public dynamic function onError(msg:String) {
	}

	public dynamic function onEnd() {
	}

	public function get_time() {
		return playing ? haxe.Timer.stamp() - playTime : 0;
	}

	public inline function get_loop() {
		return loopVideo;
	}

	public function set_loop(value : Bool) : Bool {
		return loopVideo = value;
	}

	public function dispose() {
		if( frameCacheSize > 1 ) {
			stopThread = true;
			while(stopThread)
				Sys.sleep(0.01);
		}
		if( webm != null ) {
			webm.close();
			webm = null;
		}
		if( codec != null ) {
			codec.close();
			codec = null;
		}
		if( cache != null )
			cache.dispose();
		cache = null;
		if( texture != null ) {
			texture.dispose();
			texture = null;
		}
		videoWidth = 0;
		videoHeight = 0;
		time = 0;
		playing = false;
		frameReady = false;
	}

	public function loadFile( path : String, ?onReady : Void -> Void ) {
		dispose();

		webm = hl.video.Webm.fromFile(path);
		start();
		if( onReady != null ) onReady();
	}

	function start() {
		try {
			webm.init();
		} catch(e:Any) {
			onError("Failed to init video : " + e);
			return;
		}
		codec = webm.createCodec();
		if(codec == null) {
			onError("Can't create codec " + webm.videoCodec);
			return;
		}
		var w = 0, h = 0;
		videoWidth = webm.width;
		videoHeight = webm.height;
		videoTime = 0.;
		texture = FlxG.stage.context3D.createRectangleTexture(videoWidth, videoHeight, BGRA, true);
		this.pixels = BitmapData.fromTexture(texture);
		var multithread = frameCacheSize > 1;
		cache = new FrameCache(multithread ? frameCacheSize : 1, webm.width, webm.height);
		if(multithread) {
			threadInit();
			while(!cache.isFull()) Sys.sleep(0.01);
		}
		else
			loadNextFrame();
		playing = true;
		playTime = haxe.Timer.stamp();
	}

	override public function draw():Void {
		super.draw();
	}

	function loadNextFrame() {
		cache.prepareFrame(webm, codec, loopVideo);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if( !playing )
			return;

		var frame = cache.currentFrame();
		if( frame != null && frame.state == Ended )
			playing = false;
		if( frame != null && frame.state == Ready) {
			if(frame.time == 0) {
				videoTime = 0;
			}
			if(haxe.Timer.stamp() - playTime >= frame.time) {
				texture.uploadFromByteArray(frame.pixels.getPixels(frame.pixels.rect), 0);
				videoTime = frame.time;
				cache.nextFrame();
				if(frameCacheSize <= 1)
					loadNextFrame();
			}
		}
	}

	function threadInit() {
		sys.thread.Thread.create(function() {
			var first = true;
			var finished = false;
			while(!stopThread) {
				if( cache.isFull() || finished ) {
					first = false;
					Sys.sleep(0.01);
				}
				else {
					var f = null;
					try {
						f = cache.prepareFrame(webm, codec, loopVideo);
					} catch(e : Dynamic) {
						trace(e);
					}
					if( !loopVideo && (f == null || f.state == Ended) )
						finished = true;
				}
			}
			stopThread = false;
		});
	}
}

#end