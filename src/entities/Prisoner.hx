package entities;

import h2d.col.Point;
import gamestates.PlayState;
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
	public var data: CData.Character;
	public var sprite : Sprite;
	
	var input = Controls.instance;
	public var controlled = false;
	
	public var team: Team = Friendly;
	public var body: echo.Body;
	
	public var state : ActorState = Idle;
	var attackCooldown = 0.0;
	
	var rAdd = 0.;
	var gAdd = 0.;
	var bAdd = 0.;

	public var aggroLevel = 0.;
	
	var playState: PlayState;
	
	public function new(type: CData.CharacterKind = Player, state: gamestates.PlayState) {
		super(state);
		this.playState = state;

		data = CData.character.get(type);
		friction = 20.;

		sprite = hxd.Res.loader
			.loadCache(data.Sprite, AsepriteRes)
			.toSprite(state.characterLayer);
			
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

		state.prisoners.push(this);
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
	
	public function hurt(hurter: Prisoner) {
		state = Hurt;
		if (hurter.x - x < 0) {
			sprite.scaleX = -1;
		} else {
			sprite.scaleX = 1;
		}
		sprite.animation.play("hurt", false, true);
	}
	
	public function emitAttack() {
		var target = playState.findTarget(this, sprite.scaleX);
		
		if (target != null) {
			elk.Elk.instance.sounds.playWobble(hxd.Res.sound.impact1, 0.3);
			target.flashRed();
			var p = new Point(target.x - x, target.y - y);
			p.normalize();
			p.scale(3000);
			target.ax += p.x;
			target.ay += p.y;
			target.hurt(this);
		}

		if (sprite.scaleX < 0) {
			ax -= 1000;
		} else {
			ax += 1000;
		}
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
	
	public function flashGreen() {
		gAdd = 2.0;
		bAdd = -3;
		rAdd = -3;
	}
	
	public function flashRed() {
		gAdd = -2;
		bAdd = -2;
		rAdd = 2;
	}

	var t = 0.;
	override public function tick(dt:Float) {
		super.tick(dt);
		t += dt;
		
		rAdd *= 0.82;
		gAdd *= 0.82;
		bAdd *= 0.82;
		
		sprite.color.set(1 + rAdd, 1 + gAdd, 1 + bAdd);

		if (state == Idle) {
			var sp = data.MoveSpeed * 10000 * dt;

			var ix = 0.;
			var iy = 0.;
			if (controlled) {
				ix = input.getAnalogValue(WalkX);
				iy = input.getAnalogValue(WalkY);
			}

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
			if (controlled) {
				if (input.isPressed(Attack)) {
					attack();
				}
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

		} else if(state == Hurt) {

		} else {
			if (dSq > 10 * 10) {
				sprite.animation.play("walk");
			} else {
				sprite.animation.play("idle", true, false, Math.random());
			}
		}

		body.set_position(x, y);
	}

	override function render() {
		sprite.x = Math.round(x);
		sprite.y = Math.round(y);
	}
}
