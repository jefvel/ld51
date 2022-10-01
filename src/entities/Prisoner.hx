package entities;

import elk.aseprite.AsepriteRes;
import elk.graphics.Sprite;
import h2d.Bitmap;


enum Team {
	Friendly;
	Enemy;
}

class Prisoner extends elk.entity.Entity {
	var bm:Bitmap = null;
	var lx = 0.;
	var ly = 0.;
	var data: CData.Character;
	var sprite : Sprite;
	
	var input = Controls.instance;
	
	public var team: Team = Friendly;
	
	public function new(?p) {
		data = CData.character.get(Player);
		friction = 20.;
		sprite = hxd.Res.loader.loadCache(data.Sprite, AsepriteRes).toSprite(p);
		sprite.originX = 8;
		t = Math.random() * 30;
		sprite.originY = 32;
		elk.Elk.instance.entities.add(this);
	}

	var t = 0.;
	override function tick(dt:Float) {
		super.tick(dt);
		t += dt;

		var sp = data.MoveSpeed * 10000 * dt;
		var ix = input.getAnalogValue(WalkX);
		var iy = input.getAnalogValue(WalkY);
		ax += ix * sp;
		ay += iy * sp;
		
		if (ix < 0) {
			sprite.scaleX = -1;
		} else if (ix > 0) {
			sprite.scaleX = 1;
		}

		var dSq = hxd.Math.distanceSq(vy, vx);
		var maxSpeed = data.MaxSpeed;
		if (dSq > maxSpeed * maxSpeed) {
			var d = Math.sqrt(dSq);
			vx /= d;
			vy /= d;
			vx *= maxSpeed;
			vy *= maxSpeed;
		}
		
		if (hxd.Math.distance(lx - x, ly - y) > 22) {
			//elk.Elk.instance.sounds.playSound(hxd.Res.sound.click);
			lx = x;
			ly = y;
		}

		if (dSq > 10 * 10) {
			sprite.animation.play("walk");
		} else {
			sprite.animation.play("idle");
		}
	}

	override function render() {
		// sprite.x = x;
		// sprite.y = y;
		sprite.x = interpX;
		sprite.y = interpY;
	}
}