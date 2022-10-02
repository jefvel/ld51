import gamestates.IntroState;
import gamestates.PlayState;

class Main extends elk.Elk{
	static var app: elk.Elk;

	override function init() {
		super.init();

		CData.init();

		#if debug
		app.states.current = new IntroState();
		#else
		app.states.current = new IntroState();
		#end
		sounds.sfxVolume = 2.0;
		sounds.musicVolume = 2.8;
	}
	
	override function update(dt: Float) {
		super.update(dt);
	}

	public static function main() {
		app = new Main(60, 2);
	}
}