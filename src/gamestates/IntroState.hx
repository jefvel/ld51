package gamestates;

import elk.util.EasedFloat;
import h2d.Text;
import elk.gamestate.GameState;

class IntroState extends GameState {
	var introText: h2d.Text;
	var fadeOut = new EasedFloat(1);
	override function onEnter() {
		super.onEnter();
		introText = new Text(hxd.Res.fonts.marumonica.toFont(), s2d);
		introText.textAlign = Center;
		introText.text = "Click to Start";
		
		introText.x = Math.round(game.s2d.width * 0.5);
		introText.y = Math.round(game.s2d.height * 0.5) - introText.textHeight;
	}
	
	var left = false;
	function leave() {
		if (left) {
			return;
		}

		left = true;
		fadeOut.value = 0.;
		game.sounds.playSound(hxd.Res.sound.click);
		new elk.Timeout(0.5, () -> game.states.current = new PlayState());
	}

	override function tick(dt:Float) {
		super.tick(dt);
		if (hxd.Key.isDown(hxd.Key.MOUSE_LEFT)) {
			leave();
		}
		
		s2d.alpha = fadeOut.value;
	}
}
