import hxd.Key;
import dn.heaps.input.ControllerAccess;
import dn.heaps.input.Controller;

typedef GameControlAccess = ControllerAccess<GameControls>;

enum abstract GameControls(Int) to Int {
	var WalkX;
	var WalkY;
	var Use;
	var Attack;
	var ResetGame;
}

class Controls {
	public static var instance(get, null): GameControlAccess;
	static var _instance: Controls = null;

	var input: Controller<GameControls>;
	var access: ControllerAccess<GameControls> = null;
	
	function new() {
		input = Controller.createFromAbstractEnum(GameControls);
		bindControls();
		access = input.createAccess();
	}
	
	function bindControls() {
		input.bindKeyboard(Use, Key.E);
		input.bindKeyboardAsStickXY(WalkX, WalkY, Key.W, Key.A, Key.S, Key.D);
		input.bindKeyboardAsStickXY(WalkX, WalkY, Key.UP, Key.LEFT, Key.DOWN, Key.RIGHT);
		input.bindKeyboard(Attack, [Key.SPACE, Key.X, Key.K]);
		input.bindKeyboard(ResetGame, [Key.R]);

		input.bindPad(Attack, PadButton.A);
		input.bindPadLStickXY(WalkX, WalkY);
	}
	
	static function get_instance() {
		if (_instance == null) {
			_instance = new Controls();
		}
		
		return _instance.access;
	}
}