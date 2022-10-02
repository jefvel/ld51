package entities;

import elk.util.EasedFloat;
import h2d.RenderContext;
import h2d.Text;
import h2d.ScaleGrid;
import h2d.Object;

class SpeechBubble extends Object {
	var onFinish: Void -> Void = null;
	var totalText: String;
	var bg: ScaleGrid;
	var txt: Text;
	var paddingX = 3;
	var paddingY = 2;
	public var talker: Prisoner;
	var curIndex = 0;
	public var charsPerSecond = 8;
	var elapsed = 0.;
	public var isDone = false;
	public function new(text: String, ?onFinish: Void -> Void, talker: entities.Prisoner, ?p) {
		super(p);
		this.onFinish = onFinish;
		this.totalText = text;
		bg = new ScaleGrid(hxd.Res.img.bubble.toTile(), 7, 3, 3, 7, this);
		this.txt = new Text(hxd.Res.fonts.marumonica.toFont(), this);
		txt.x = paddingX;
		txt.y = paddingY;
		txt.textColor = 0x000000;
		txt.maxWidth = 148;
		txt.text = text;
		bg.width = paddingX * 2 + txt.textWidth;
		bg.height = paddingY * 2 + txt.textHeight + 4;
		this.talker = talker;
		txt.text = "";
	}
	
	public var delay = 0.3;
	
	var alphaa = new EasedFloat(1, 0.3);
	public function hide() {
		alphaa.value = 0.;
	}
	
	public function finish() {
		curIndex = totalText.length;
		txt.text = totalText;
		isDone = true;

		if (talker == null) return;
		var b = getBounds();
		x = talker.x;
		y = talker.y - talker.data.Height - b.height;
	}

	var charr = 0;
	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		bg.visible = curIndex > 0;
		if (delay > 0) {
			delay -= ctx.elapsedTime;
			return;
		}

		if (curIndex < totalText.length) {
			elapsed += ctx.elapsedTime;
			if (elapsed > 1/charsPerSecond) {
				curIndex ++;
				charr ++;
				if (charr >= 4) {
					elk.Elk.instance.sounds.playSound(hxd.Res.sound.chatter1, 0.2);
					charr = 0;
				}
			}
			txt.text = totalText.substr(0, curIndex);
		} else {
			isDone = true;
		}

		if (talker == null) return;
		var b = getBounds();
		x = talker.x;
		y = talker.y - talker.data.Height - b.height;
		this.alpha = alphaa.value;
		if (this.alpha == 0) {
			remove();
		}
	}
	
	public function update(dt: Float) {
		
	}
}