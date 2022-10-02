package entities;

import elk.util.EasedFloat;
import elk.aseprite.AsepriteData;
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
	Jumping;
	Dead;
}

class Prisoner extends Actor {
	var bm:Bitmap = null;

	var aggroGainPerAttack = 1.0;
	public var lives = 0;

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
	
	public var cowardice = 0.0;
	public var rage = 0.0;
	static var heartFrames: AsepriteData = null;
	var livesBm: Bitmap;
	
	public var offsetY = new EasedFloat(0, 0.3);
	
	var untilIdleMove = Math.random() * 3 + 1;

	public function new(type: CData.CharacterKind = Player, state: gamestates.PlayState) {
		super(state);
		offsetY.easeFunction = elk.M.bounceOut;
		this.playState = state;
		if (heartFrames == null) {
			heartFrames = hxd.Res.img.hearts.toAseData();
		}

		livesBm = new Bitmap(heartFrames.frames[0].tile, state.fg);

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

		lives = data.Health;

		body.on_move = setPhysPos;
		sprite.animation.onEnd = animationEnd;
		sprite.animation.onEnterFrame = onEnterFrame;

		state.prisoners.push(this);
		cowardice = Math.random();
	}
	
	public function reAddToScene() {
		playState.fg.addChild(livesBm);
		playState.characterLayer.addChild(sprite);
	}

	var jumpX = 0.;
	public function jump(targetX : Float) {
		jumpVel = -4.;
		state = Jumping;
		jumpX = targetX;
	}
	
	public function finishJump() {
		state = Idle;
		jumpVel = 0;
		z = 0;
	}
	
	function animationEnd(name: String) {
		if (state == Dead) return;

		if (name == "attack" || name == "hurt") {
			state = Idle;
		}
	}
	
	public function disintegrate() {
		state = Dead;
		friction = 1.001;
		vz = -20;
		vx = (Math.random() - 0.5) * 10;
		sprite.animation.play("disintegrate");
		playState.killPrisoner(this);
	}
	
	public var untilDisintegrate = 0.9;
	
	function emitFootstep() {
		var s = [
			hxd.Res.sound.step1,
			hxd.Res.sound.step2,
			hxd.Res.sound.step3,
		].randomElement();
		
		elk.Elk.instance.sounds.playWobble(s, 0.2);
	}
	
	public function hurt(hurter: Prisoner) {
		if (state == Dead) return;

		state = Hurt;
		if (hurter.x - x < 0) {
			sprite.scaleX = -1;
		} else {
			sprite.scaleX = 1;
		}

		if (!controlled) {
			attackTarget = hurter;
		}
		
		lives --;
		if (lives <= 0) {
			lives = 0;
			disintegrate();
		}

		sprite.animation.play("hurt", false, true);
	}
	
	public function emitAttack() {
		var target = playState.findTarget(this, sprite.scaleX);
		
		if (target != null) {
			elk.Elk.instance.sounds.playWobble(hxd.Res.sound.impact1, 0.3);
			target.flash();
			var p = new Point(target.x - x, target.y - y);
			p.normalize();
			p.scale(5000);
			target.ax += p.x;
			target.ay += p.y;
			target.hurt(this);

			aggroLevel += aggroGainPerAttack;
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

	var fspeed = 0.86;
	public function flash() {
		gAdd = 100;
		bAdd = 100;
		rAdd = 100;
		fspeed = 0.5;
	}
	
	public function flashGreen() {
		gAdd = 2.0;
		bAdd = -3;
		rAdd = -3;
		fspeed = 0.86;
	}
	
	public function flashRed() {
		gAdd = -2;
		bAdd = -2;
		rAdd = 2;
		fspeed = 0.86;
	}
	
	var exploded = false;
	var smoke: Sprite;
	function explode() {
		if (exploded) return;
		exploded = true;
		var s = hxd.Res.img.smoke.toSprite(playState.laserContainer);
		smoke = s;
		s.originX = 32;
		s.originY = 48;
		flash();
		fspeed = 1.0;
		s.x = sprite.x;
		s.y = sprite.y - 8;

		s.animation.play("poof", false);
		playState.game.sounds.playWobble(hxd.Res.sound.disintegrate, 0.2);
		s.animation.onEnd = explosionEnd;
		s.animation.onEnterFrame = explosionFrameEnter;
	}
	
	function explosionFrameEnter(frame: Int) {
		if (frame == 3) {
			sprite.visible = false;
		}
	}
	
	function explosionEnd(e: String) {
		playState.removePrisoner(this);
		smoke.remove();
	}
	
	public var attackTarget : Prisoner = null;
	
	var jumpVel = 0.;
	var jumpAcc = 0.;

	var targetX = 0.;
	var targetY = 0.;

	var t = 0.;
	override public function tick(dt:Float) {
		super.tick(dt);
		t += dt;
		
		rAdd *= fspeed;
		gAdd *= fspeed;
		bAdd *= fspeed;
		
		sprite.color.set(1 + rAdd, 1 + gAdd, 1 + bAdd);
		
		if (state == Idle) {
			var sp = data.MoveSpeed * 10000 * dt;

			var ix = 0.;
			var iy = 0.;
			if (controlled) {
				ix = input.getAnalogValue(WalkX);
				iy = input.getAnalogValue(WalkY);
			}
			
			if (attackTarget != null && attackTarget.state == Dead) {
				attackTarget = null;
			}

			if (!controlled) {
				var wantToStayInSafeZone = false;
				if (playState.timeUntilScan < 2 + cowardice * 2.5 || playState.laser.scanning) {
					var t = playState.findClosestSafeZone(x, y);
					if (t != null) {
						wantToStayInSafeZone = true;
						var dx = t.x - x;
						var dy = t.y - y;
						var minDist = 8;
						if (Math.abs(dx) > minDist) {
							if (dx < 0) ix = -1;
							else ix = 1;
						}

						if (Math.abs(dy) > minDist) {
							if (dy < 0) iy = -1;
							else iy = 1;
						}
					}
				}

				if (attackTarget != null && state != Attacking) {
					var tx = attackTarget.x;
					if (tx > x)
						tx -= 16;
					else 
						tx += 16;

					var dx = tx - x;
					var dy = attackTarget.y - y;
					var minDist = 9;
					var inRange = true;

					if (Math.abs(dx) > 3) {
						if (!wantToStayInSafeZone) {
							if (dx < 0)
								ix = -1;
							else 
								ix = 1;
						}
						sprite.scaleX = dx < 0 ? -1 : 1;
						inRange = false;
					}

					if (Math.abs(dy) > minDist) {
						if (!wantToStayInSafeZone) {
							if (dy < 0)
								iy = -1;
							else 
								iy = 1;
						}
						inRange = false;
					}
					
					if (inRange) {
						attack();
					}
				}

				
				var id = Math.sqrt(ix * ix + iy * iy);
				if (id > 0) {
					ix /= id;
					iy /= id;
				}
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
		
		if (state == Jumping) {
			jumpVel += dt * 17;
			z += jumpVel;
			var dx = jumpX - x;
			ax = dx / dt;
		}

		var dSq = hxd.Math.distanceSq(vy, vx);
		var maxSpeed = data.MaxSpeed;
		if (state != Hurt) {
			if (dSq > maxSpeed * maxSpeed) {
				var d = Math.sqrt(dSq);
				vx /= d;
				vy /= d;
				vx *= maxSpeed;
				vy *= maxSpeed;
			}
		}


		if (state == Jumping) {
			sprite.animation.play("jump");
		} else if (state == Attacking) {

		} else if(state == Hurt) {

		} else if (state == Dead) {
			untilDisintegrate -= dt;
			if (untilDisintegrate <= 0) {
				explode();
			}
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
		sprite.y = Math.round(y + z);

		if (state != Dead && (controlled || lives < data.Health) && state != Jumping) {
			livesBm.x = sprite.x - 16;
			livesBm.y = sprite.y + 2;
			livesBm.tile = heartFrames.frames[lives].tile;
			livesBm.visible = true;
		} else {
			livesBm.visible = false;
		}
	}
}
