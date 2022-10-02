package gamestates;

import h2d.Text;
import elk.Timeout;
import elk.graphics.Sprite;
import h2d.col.Point;
import entities.Laser;
import h2d.filter.ColorMatrix;
import entities.SafeZone;
import h2d.Graphics;
import entities.Actor;
import elk.util.EasedFloat;
import h2d.Bitmap;
import elk.graphics.filter.RetroFilter;
import h2d.Object;
import entities.Prisoner;
import elk.gamestate.GameState;

class PlayState extends GameState {
	var controls = Controls.instance;
	var arm: Bitmap;
	var time = 0.;
	var secondProgress = 0.;
	
	var checkTime = 3.;

	var currentSecond = 0;
	var interval = 10;
	public var timeUntilScan = 10.;
	var armRotation = new EasedFloat(-Math.PI * 0.5, 0.3);
	
	var container: Object;
	var world: Object;
	var worldMask:Bitmap;
	var f: RetroFilter;
	var bg: Object;
	public var fg: Object;

	var safeZoneContainer: Object;
	public var characterLayer: h2d.ZGroup;
	public var laserContainer: Object;

	var player: Prisoner;
	
	public var laser: Laser;

	var level: Levels_Level;
	
	public var actors: Array<Actor> = [];
	public var prisoners: Array<Prisoner> = [];

	public var physics: echo.World;
	var statics : Array<echo.Body>= [];
	var dynamics: Array<echo.Body> = [];
	
	var debugGraphics: Graphics;
	var vault: Sprite;
	
	public var safeZones: Array<SafeZone> = [];

	public function new() {
		super();
	}
	
	public function resetGame() {
		game.states.current = new PlayState();
	}
	var colorFilter: ColorMatrix;
	
	override function onEnter() {
		super.onEnter();

		armRotation.easeFunction = elk.M.elasticOut;

		f = new RetroFilter(0.6, 0.2, 0.2);
		game.s2d.filter = f;

		container = new Object(s2d);
		world = new Object(container);
		worldMask = new Bitmap(h2d.Tile.fromColor(0xffffff), world);
		colorFilter = new ColorMatrix(h3d.Matrix.S(1.1, 1.1, 1.2));
		world.filter = new h2d.filter.Group([
			colorFilter,
			new h2d.filter.Mask(worldMask),
		]);

		bg = new Object(world);
		safeZoneContainer = new Object(world);
		characterLayer = new h2d.ZGroup(world);
		laserContainer = new Object(world);
		
		fg = new Object(world);

		debugGraphics = new Graphics(world);

		var allLevels = new Levels();
		
		var l = allLevels.all_levels.Level_0;

		loadLevel(l);
	}
	
	function loadLevel(l: Levels_Level) {
		bg.removeChildren();
		fg.removeChildren();
		characterLayer.removeChildren();
		
		level = l;
		
		worldMask.tile.scaleToSize(l.pxWid, l.pxHei);

		physics = echo.Echo.start({
			width: level.pxWid,
			height: level.pxHei,
			gravity_y: 0,
			iterations: 2
		});
		
		for (coll in level.l_Collisions.all_CollisionBox) {
			var body = physics.make({
				mass: STATIC,
				material: {elasticity: 1},
				x: coll.pixelX + coll.width * 0.5,
				y: coll.pixelY + coll.height * 0.5,
				shape: {
					type: RECT,
					width: coll.width,
					height: coll.height,
				},
			});

			statics.push(body);
		}
		
		hxd.Res.img.tiles.toTile();

		bg.addChild(l.l_Tiles.render());
		vault = hxd.Res.img.vault.toSprite(bg);
		vault.originX = vault.originY = 16;
		vault.animation.play("closed");
		for (v in l.l_Entities.all_Vault) {
			vault.x = v.pixelX;
			vault.y = v.pixelY;
		}

		fg.addChild(l.l_Foreground.render());
		
		for (z in l.l_SafeZones.all_SafeZone) {
			var s = new SafeZone(safeZoneContainer);
			s.x = z.pixelX;
			s.y = z.pixelY;
			safeZones.push(s);
		}

		var face = new Bitmap(hxd.Res.img.clockface.toTile(), bg);
		face.tile.dx = face.tile.dy = -16;
		arm = new Bitmap(hxd.Res.img.clockarm.toTile(), face);
		arm.tile.dx = -2;
		arm.tile.dy = -2;
		
		var armPos = l.l_Entities.all_ClockArm[0];
		face.x = armPos.pixelX;
		face.y = armPos.pixelY;
		
		laser = new Laser(this, laserContainer);
		laser.onScanDone = onScanDone;
		
		player = new Prisoner(Player, this);
		player.controlled = true;
		var spawnPos = l.l_Entities.all_PlayerSpawn[0];
		player.setPos(spawnPos.pixelX, spawnPos.pixelY);
		dynamics.push(player.body);
		
		for (i in 0...14) {
			spawnPrisoner();
		}
	}
	
	public function killPrisoner(p: Prisoner) {
		dynamics.remove(p.body);
		prisoners.remove(p);
		if (p == player) {
			loseGame();
		}
	}
	
	public function removePrisoner(p: Prisoner) {
		killPrisoner(p);
		actors.remove(p);
		p.sprite.remove();
		if (p == player) {
			loseGameFinish();
		}
	}
	
	var timeScale = new EasedFloat(1.0, 0.5);
	public function loseGame() {
		timeScale.setImmediate(0.5);
	}

	public function loseGameFinish() {
		new Timeout(0.3, () -> {
			timeScale.value = 1.0;
			var bm = new Bitmap(h2d.Tile.fromColor(0x333333), container);
			var t = new Text(hxd.Res.fonts.marumonica.toFont(), container);
			t.textAlign = Center;
			bm.alpha = 0.5;
			bm.x = -64;
			bm.rotation = -Math.PI * 0.01;
			bm.blendMode = Multiply;
			new Timeout(0.4, () -> {
				var m = colorFilter.matrix;
				m.colorSaturate(-1);
				colorFilter.matrix = m;
				t.text = "DISINTEGRATED";
				t.x = Math.round(game.s2d.width * 0.5);
				t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);

				bm.y = t.y - 8;
				bm.tile.scaleToSize(game.s2d.width + 128, t.textHeight + 37);

				new Timeout(0.65, () -> {
					t.text += "\nPress attack to try again";
					t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);

					bm.y = t.y - 8;
					bm.tile.scaleToSize(game.s2d.width + 128, t.textHeight + 37);

					canRestart = true;
				});
			});
		});
	}
	
	public var canRestart = false;
	
	public function spawnPrisoner() {
		var p = new Prisoner(Enemy, this);
		var s = level.l_Entities.all_EnemySpawn[0];
		p.setPos(s.pixelX + s.width * Math.random(), s.pixelY + s.height * Math.random());
		dynamics.push(p.body);
	}
	
	var vaultOpen = false;
	public function openVault() {
		if (vaultOpen) return;
		vaultOpen = true;
		vault.animation.play("opening", false);
		vault.animation.onEnd = s -> {
			vault.animation.play("opened");
		}
	}
	
	function onScanDone() {
		var aliveZones = 0;
		for (s in safeZones) {
			if (s.isActive) {
				aliveZones ++;
			}
		}
		if (aliveZones == 0) {
			openVault();
		}
	}
	
	public function inSafeZone(x: Float, y: Float) {
		for (s in safeZones) {
			if (!s.isActive) {
				continue;
			}

			if (Math.abs(x - s.x) < 24 * 0.5) {
				if (Math.abs(y - s.y) < 24 * 0.5) {
					return s;
				}
			}
		}
		
		return null;
	}

	public function findClosestSafeZone(x: Float, y: Float): SafeZone {
		var closest = null;
		var dst = Math.POSITIVE_INFINITY;
		for (c in safeZones) {
			if (!c.isActive) continue;
			var dx = x - (c.x); 
			var dy = y - (c.y); 
			var d = dx * dx + dy * dy;
			if (d * d < dst) {
				dst = d * d;
				closest = c;
			}
		}

		return closest;
	}
	
	function updateCamBounds() {
		if (game.s3d.camera.orthoBounds == null) {
			return;
		}

		var b = game.s3d.camera.orthoBounds;
		b.xMin = 0;
		b.xMax = game.s2d.width;

		b.yMax = game.s2d.height;
		b.yMin = 0;

		b.zMin = -4000;
		b.zMax = 4000;

		game.s3d.camera.update();
	}
	
	var intervalsBeaten = 0;
	function intervalComplete() {
		intervalsBeaten ++;
		laser.startScan();
	}
	
	var ticked = false;
	function passTime(dt: Float) {
		secondProgress += dt;
		if (secondProgress >= 1) {
			secondProgress -= 1;
			currentSecond ++;
			ticked = !ticked;
			if (ticked) {
				if (currentSecond >= 7)
					game.sounds.playSound(hxd.Res.sound.ticklong, 0.4);
				else 
					game.sounds.playSound(hxd.Res.sound.tick, 0.2);
			} else {
				if (currentSecond >= 7)
					game.sounds.playSound(hxd.Res.sound.tocklong, 0.4);
				else 
					game.sounds.playSound(hxd.Res.sound.tock, 0.2);
			}
			if (currentSecond >= interval) {
				currentSecond = 0;
				intervalComplete();
			}
			armRotation.value = (intervalsBeaten + currentSecond / interval) * Math.PI * 2 - Math.PI * 0.5;
		}

		timeUntilScan = interval - (secondProgress + currentSecond);
	}

	override function tick(dt:Float) {
		super.tick(dt);
		time += dt;

		passTime(dt);
		arm.rotation = armRotation.value;

		for (e in actors) {
			e.preTick();
		}

		for (e in actors) {
			e.tick(dt);
		}
		
		#if debug
		if (hxd.Key.isPressed(hxd.Key.P)) {
			secondProgress = 7;
		}
		#end
		
		if (controls.isPressed(ResetGame)) {
			resetGame();
		}
		
		if (canRestart && controls.isPressed(Attack)) {
			resetGame();
		}
		
		var alive = 0;
		for (p in prisoners) {
			if (p.state != Dead) {
				alive ++;
			}
		}
		if (alive == 1) {
			openVault();
		}

		physics.check(dynamics, statics);
		physics.check(dynamics, dynamics);
		
		// f.transition = Math.sin(time);

		updateCamBounds();
	}
	
	public function findTarget(attacker: Prisoner, dirX = 1.): Prisoner {
		var d = new Point();
		var d2 = new Point(dirX, 0);

		for (p in prisoners) {
			if (p == attacker) {
				continue;
			}
			
			if (p.state == Dead) {
				continue;
			}
			
			d.set(p.x - attacker.x, p.y - attacker.y);

			if (d.normalized().dot(d2) < 0.3) {
				continue;
			}

			var prSq = attacker.data.Radius + p.data.Radius + attacker.data.AttackRange;
			prSq = prSq * prSq;
			
			if (d.lengthSq() < prSq) {
				return p;
			}
		}
		
		return null;
	}
	
	override function update(dt: Float) {
		super.update(dt);
		game.timeScale = timeScale.value;
		
		for (e in actors) {
			e.render();
		}
		
		characterLayer.ysort(0);

		var w = Math.floor((game.s2d.width - level.pxWid) * 0.5);
		var h = Math.floor((game.s2d.width - level.pxWid) * 0.5);

		world.x = w;
		world.y = h;

		var sfAlpha = (timeUntilScan < checkTime || laser.scanning) ? 1.0 : 0.1;
		for (s in safeZones) {
			if (s.isActive) {
				s.alpha = sfAlpha;
			} else {
				s.alpha *= 0.98;
			}
		}
	}
}
