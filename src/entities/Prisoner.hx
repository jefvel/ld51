package entities;

import elk.aseprite.AsepriteRes;
import elk.graphics.Sprite;
import h2d.Bitmap;


enum Team {
	Friendly;
	Enemy;
}

enum ActorState {
	Idle;
	Attacking;
	Hurt;
	Dead;
}

class Prisoner extends Actor {
	var bm:Bitmap = null;
	var data: CData.Character;
	var sprite : Sprite;
	
	var input = Controls.instance;
	public var controlled = false;
	
	public var team: Team = Friendly;
	public var body: echo.Body;
	
	public var state : ActorState = Idle;
	var attackCooldown = 0.0;
	
	public var aggroLevel = 0.;
	
	public function new(type: CData.CharacterKind = Player, state: gamestates.PlayState) {
		data = CData.character.get(type);
		friction = 20.;

		sprite = hxd.Res.loader
			.loadCache(data.Sprite, AsepriteRes)
			.toSprite(state.actors);
			
		sprite.originX = 16;
		t = Math.random() * 30;
		sprite.originY = 32;
		
		body  = state.physics.make({
			shape: {
				type: CIRCLE,
				radius: data.Radius,
			},
		});

		body.on_move = setPhysPos;
		sprite.animation.onEnd = animationEnd;
		sprite.animation.onEnterFrame = onEnterFrame;
	}
	
	function animationEnd(name: String) {
		if (name == "attack" || name == "hurt") {
			state = Idle;
		}
	}
	
	function emitFootstep() {
		var s = [
			hxd.Res.sound.step1,
			hxd.Res.sound.step2,
			hxd.Res.sound.step3,
		].randomElement();
		
		elk.Elk.instance.sounds.playWobble(s, 0.2);
	}
	
	public function emitAttack() {
		elk.Elk.instance.sounds.playWobble(hxd.Res.sound.impact1, 0.3);
	}
	
	function onEnterFrame(frame: Int) {
		for (e in data.FrameEvents) {
			if (e.Frame == frame) {

				if (e.Event == Attack) {
					emitAttack();
				}
				
				if (e.Event == Step) {
					emitFootstep();
				}

				break;
			}
		}
	}
	
	function setPhysPos(x: Float, y: Float) {
		this.x = x;
		this.y = y;
	}
	
	public function setPos(x: Float, y: Float) {
		this.x = body.x = x;
		this.y = body.y = y;
	}
	
	public function attack() {
		state = Attacking;
		attackCooldown = data.AttackCooldown;
		elk.Elk.instance.sounds.playWobble(hxd.Res.sound.swoosh1, 0.3);
		sprite.animation.play("attack", false, true);
	}

	var t = 0.;
	override public function tick(dt:Float) {
		super.tick(dt);
		t += dt;

		if (state == Idle) {
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
		}

		if (attackCooldown > 0) {
			attackCooldown -= dt;
		}

		if (state == Idle || state == Attacking && attackCooldown <= 0) {
			if (input.isPressed(Attack)) {
				attack();
			}
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

		if (state == Attacking) {

		} else {
			if (dSq > 10 * 10) {
				sprite.animation.play("walk");
			} else {
				sprite.animation.play("idle");
			}
		}

		body.set_position(x, y);
	}

	override function render() {
		sprite.x = Math.round(x);
		sprite.y = Math.round(y);
	}
}