package gamestates;

import elk.util.EasedFloat;
import h2d.Bitmap;
import elk.graphics.filter.RetroFilter;
import h2d.Object;
import entities.Prisoner;
import hxd.res.DefaultFont;
import h2d.Text;
import elk.gamestate.GameState;

class PlayState extends GameState {
	var tickRateTxt: Text;
	
	var controls = Controls.instance;
	var arm: Bitmap;
	var time = 0.;
	var secondProgress = 0.;

	var currentSecond = 0;
	var interval = 10;
	var armRotation = new EasedFloat(-Math.PI * 0.5, 0.3);
	
	var container: Object;
	var world: Object;
	var f: RetroFilter;
	var bg: Object;
	var player: Prisoner;
	var level: Levels_Level;
	
	var ents: Array<elk.entity.Entity> = [];

	public function new() {
		super();
	}
	
	override function onEnter() {
		super.onEnter();
		armRotation.easeFunction = elk.M.elasticOut;

		f = new RetroFilter(0.6, 0.2, 0.3);
		game.s2d.filter = f;

		container = new Object(s2d);
		world = new Object(container);
		world.filter = new h2d.filter.Nothing();
		bg = new Object(world);
		var allLevels = new Levels();
		
		var l = allLevels.all_levels.Level_0;
		level = l;
		bg.addChild(l.l_Tiles.render());
		//sy.easeFunction = elk.T.elasticOut;

		tickRateTxt = new Text(DefaultFont.get(), s2d);
		tickRateTxt.textColor = 0xffffff;

		var face = new Bitmap(hxd.Res.img.clockface.toTile(), world);
		face.tile.dx = face.tile.dy = -16;
		arm = new Bitmap(hxd.Res.img.clockarm.toTile(), face);
		arm.tile.dx = -2;
		arm.tile.dy = -2;
		
		var armPos = l.l_Entities.all_ClockArm[0];
		face.x = armPos.pixelX;
		face.y = armPos.pixelY;
		
		player = new Prisoner(world);
		var spawnPos = l.l_Entities.all_PlayerSpawn[0];
		player.x = spawnPos.pixelX;
		player.y = spawnPos.pixelY;
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
	
	function passTime(dt: Float) {
		secondProgress += dt;
		if (secondProgress >= 1) {
			secondProgress -= 1;
			currentSecond ++;
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
		
		// f.transition = Math.sin(time);

		updateCamBounds();
	}
	
	override function update(dt: Float) {
		super.update(dt);
		var w = Math.floor((game.s2d.width - level.pxWid) * 0.5);
		var h = Math.floor((game.s2d.width - level.pxWid) * 0.5);
		world.x = w;
		world.y = h;
	}
}
