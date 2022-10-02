package gamestates;

import elk.Timeout;
import elk.util.EasedFloat;
import h2d.Object;
import elk.gamestate.GameState;

class WinState extends GameState {
	var state: PlayState;
	public function new(playState: PlayState) {
		super();
		state = playState;
	}
	
	var container: Object;
	var input = Controls.instance;
	override function onEnter() {
		super.onEnter();

		fadeOut.setImmediate(0);
		fadeOut.value = 1.0;

		container = new Object(s2d);
		var bm = new h2d.Bitmap(hxd.Res.img.winner.toTile(), container);
		bm.tile.setCenterRatio();
		bm.x = Math.round(game.s2d.width * 0.5);
		bm.y = Math.round(game.s2d.height * 0.5);
		container.alpha = 0.;
	}
	
	var fadeOut = new EasedFloat(1, 1.0);
	var fadingOut = false;
	var elapsed = 0.;
	override function tick(dt:Float) {
		super.tick(dt);
		container.alpha = fadeOut.value;
		elapsed += dt;
		if (elapsed < 0.8) {
			return;
		}

		if (!fadingOut) {
			if (input.isPressed(Attack)) {
				fadeOut.value = 0.;
				fadingOut = true;
				new Timeout(1.2, () -> game.states.current = new PlayState());
			}
		}
	}
}