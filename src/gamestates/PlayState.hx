package gamestates;

import h2d.filter.ColorMatrix;
import entities.SafeZone;
import h2d.Graphics;
import entities.Actor;
import elk.util.EasedFloat;
import h2d.Bitmap;
import elk.graphics.filter.RetroFilter;
import h2d.Object;
import entities.Prisoner;
import hxd.res.DefaultFont;
import h2d.Text;
import elk.gamestate.GameState;

class PlayState extends GameState {
	var controls = Controls.instance;
	var arm: Bitmap;
	var time = 0.;
	var secondProgress = 0.;
	
	var checkTime = 2.;

	var currentSecond = 0;
	var interval = 10;
	var armRotation = new EasedFloat(-Math.PI * 0.5, 0.3);
	
	var container: Object;
	var world: Object;
	var f: RetroFilter;
	var bg: Object;
	var fg: Object;

	var safeZoneContainer: Object;
	public var actors: h2d.ZGroup;

	var player: Prisoner;

	var level: Levels_Level;
	
	var ents: Array<Actor> = [];

	public var physics: echo.World;
	var statics : Array<echo.Body>= [];
	var dynamics: Array<echo.Body> = [];
	
	var debugGraphics: Graphics;
	
	public var safeZones: Array<SafeZone> = [];

	public function new() {
		super();
	}
	
	override function onEnter() {
		super.onEnter();

		armRotation.easeFunction = elk.M.elasticOut;

		f = new RetroFilter(0.6, 0.2, 0.2);
		game.s2d.filter = f;

		container = new Object(s2d);
		world = new Object(container);
		world.filter = new h2d.filter.ColorMatrix(h3d.Matrix.S(1.1, 1.1, 1.2));

		bg = new Object(world);
		safeZoneContainer = new Object();
		actors = new h2d.ZGroup(world);
		
		fg = new Object(world);

		debugGraphics = new Graphics(world);

		var allLevels = new Levels();
		
		var l = allLevels.all_levels.Level_0;

		loadLevel(l);
	}
	
	function loadLevel(l: Levels_Level) {
		bg.removeChildren();
		fg.removeChildren();
		actors.removeChildren();
		
		level = l;
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
		fg.addChild(l.l_Foreground.render());

		var face = new Bitmap(hxd.Res.img.clockface.toTile(), world);
		face.tile.dx = face.tile.dy = -16;
		arm = new Bitmap(hxd.Res.img.clockarm.toTile(), face);
		arm.tile.dx = -2;
		arm.tile.dy = -2;
		
		var armPos = l.l_Entities.all_ClockArm[0];
		face.x = armPos.pixelX;
		face.y = armPos.pixelY;
		
		player = new Prisoner(Player, this);

		var spawnPos = l.l_Entities.all_PlayerSpawn[0];
		player.setPos(spawnPos.pixelX, spawnPos.pixelY);

		dynamics.push(player.body);

		ents.push(player);
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
	}
	
	var ticked = false;
	function passTime(dt: Float) {
		secondProgress += dt;
		if (secondProgress >= 1) {
			secondProgress -= 1;
			currentSecond ++;
			ticked = !ticked;
			if (ticked) {
				game.sounds.playSound(hxd.Res.sound.tick, 0.2);
			} else {
				game.sounds.playSound(hxd.Res.sound.tock, 0.2);
			}
			if (currentSecond >= interval) {
				currentSecond = 0;
				intervalComplete();
			}
			armRotation.value = (intervalsBeaten + currentSecond / interval) * Math.PI * 2 - Math.PI * 0.5;
		}
	}

	override function tick(dt:Float) {
		super.tick(dt);
		time += dt;

		passTime(dt);
		arm.rotation = armRotation.value;

		for (e in ents) {
			e.preTick();
		}

		for (e in ents) {
			e.tick(dt);
		}

		physics.check(dynamics, statics, { separate: true });

		// f.transition = Math.sin(time);

		updateCamBounds();
	}
	
	override function update(dt: Float) {
		super.update(dt);
		
		for (e in ents) {
			e.render();
		}
		
		actors.ysort(0);

		var w = Math.floor((game.s2d.width - level.pxWid) * 0.5);
		var h = Math.floor((game.s2d.width - level.pxWid) * 0.5);

		world.x = w;
		world.y = h;
	}
}
