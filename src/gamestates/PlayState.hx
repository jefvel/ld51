package gamestates;

import entities.SpeechBubble;
import h3d.Vector;
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
	public var time = 0.;
	var score(default, set): Int = 0;
	function set_score(s: Int) {
		scoreEased.value = s;
		return score = s;
	}

	public var teeth = 0;

	var scoreEased = new EasedFloat(0, 0.2);
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
	
	var playTimeText: Text;
	var scoreText: Text;
	// var toothText: Text;
	public var fg: Object;
	
	public var musicChannel: hxd.snd.Channel;

	var safeZoneContainer: Object;
	public var characterLayer: h2d.ZGroup;
	public var laserContainer: Object;
	
	public var uiContainer: Object;

	public var player: Prisoner;
	public var judge: Prisoner = null;
	
	public var laser: Laser;

	public var level: Levels_Level;
	
	public var actors: Array<Actor> = [];
	public var prisoners: Array<Prisoner> = [];

	public var physics: echo.World;
	var statics : Array<echo.Body>= [];
	var dynamics: Array<echo.Body> = [];
	
	var groundGraphics: Graphics;
	var debugGraphics: Graphics;
	var vaultMask: Bitmap;
	var vaultMaskContainer: Bitmap;
	public var vault: Sprite;
	
	public var toothArray: Array<entities.Tooth> = [];
	
	public var safeZones: Array<SafeZone> = [];
	public var safeZoneCount = 0;

	public function new() {
		super();
	}
	
	public function resetGame() {
		game.states.current = new PlayState();
	}
	var colorFilter: ColorMatrix;
	
	var levelIndex = 0;
	var levels: Array<Levels_Level> = [];
	
	var cachedTexts: Array<{
		txt: Text,
		untilFade: Float,
	}> = [];
	var cacheTextIndex = 0;
	public function showTextPopup(score: Int, x: Float, y: Float) {
		var t = null;
		if (cachedTexts.length < 10) {
			var txt = new Text(hxd.Res.fonts.small.toFont(), uiContainer);
			t = {
				txt: txt,
				untilFade: 0.4,
			};
			cachedTexts.push(t);
			t.txt.textAlign = Center;
		} else {
			cacheTextIndex ++;
			if (cacheTextIndex > cachedTexts.length - 1) {
				cacheTextIndex = 0;
			}
			t = cachedTexts[cacheTextIndex];
		}
		
		t.txt.text = score.toMoneyString();
		t.txt.x = Math.round( world.x + x + Math.random() * 16 - 8);
		t.txt.y = Math.round(world.y + y + Math.random() * 16 - 8);
		t.untilFade = 0.4;
	}
	
	public function spawnTooth(x: Float, y: Float, amount = 1) {
		for (i in 0...amount) {
			var t = new entities.Tooth(bg);
			t.px = x + (Math.random() - 0.5) * 8;
			t.py = y + (Math.random() - 0.5) * 8 - 23;
			toothArray.push(t);
		}
	}
	
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
		var all = allLevels.all_levels;
		levels = [
			all.Menu,
			//all.Boss,
			all.Level_0,
			all.Level_1,
			all.Level_2,
			all.Level_3,
			all.Level_4,
			all.Boss,
		];

		//worldOffsetY.easeFunction = elk.M.expoOut;
		
		flashBm = new Bitmap(h2d.Tile.fromColor(0xf1f2da), container);
		flashBm.visible = false;
		
		loadNextLevel();
		uiContainer = new Object(container);
		scoreText = new Text(hxd.Res.fonts.gridgazer.toFont(), uiContainer);
		scoreText.x = 8;
		scoreText.y = 5;
		scoreText.scale(0.5);
		

		playTimeText = new Text(hxd.Res.fonts.marumonica.toFont(), uiContainer);
		playTimeText.y = scoreText.textHeight * 0.5 + scoreText.y;
		playTimeText.x = scoreText.x;
		
		// var t = new Bitmap(hxd.Res.img.tooth.toTile(), uiContainer);
		// toothText = new Text(hxd.Res.fonts.marumonica.toFont(), uiContainer);
		// toothText.x = playTimeText.x + 16;
		// toothText.y = playTimeText.y + playTimeText.textHeight + 4;
		// t.x = playTimeText.x + 2;
		// t.y = toothText.y + 5;

		musicChannel = game.sounds.playMusic(hxd.Res.sound.mainsong, 0.33);
		musicChannel.volume = 0;
	}
	
	var musicStarted = false;
	public function startMusic() {
		if (musicStarted) return;
		musicStarted = true;
		musicChannel.position = 0;
		musicChannel.volume = 0.33;
	}
	
	override function onRemove() {
		super.onRemove();
		if (musicChannel != null) {
			musicChannel.fadeTo(0, 0.1, () -> musicChannel.stop());
		}
	}
	
	function loadNextLevel(immediate = false) {
		var l = levels[levelIndex];

		levelIndex ++;

		if (level == null || immediate) {
			worldOffsetY.value = -1;
			loadLevel(l);
		} else {
			worldOffsetY.easeTime = 2.0;
			worldOffsetY.value = -1;
			game.sounds.playSound(hxd.Res.sound.swoosh, 0.1);
			new Timeout(2.5, () -> {
				loadLevel(l);
				worldOffsetY.easeTime = 1.2;
			});
		}
	}
	
	public var isMenu = false;
	
	var worldOffsetY = new EasedFloat(0, 1.2);
	function loadLevel(l: Levels_Level) {
		running = false;
		bg.removeChildren();
		fg.removeChildren();

		isMenu = l.f_MenuLevel;
		
		vault = null;
		vaultOpen = false;

		currentSecond = 0;
		secondProgress = 0;
		intervalsBeaten = 0;
		timeUntilScan = interval;
		armRotation.setImmediate(-Math.PI * 0.5);
		
		characterLayer.removeChildren();
		safeZoneContainer.removeChildren();
		characterLayer.removeChildren();
		laserContainer.removeChildren();
		
		toothArray = [];

		for (a in actors) {
			if (a == player) continue;
			actors.remove(a);
		}

		for (e in prisoners) {
			if (e == player) {
				continue;
			}

			prisoners.remove(e);
			actors.remove(e);
			dynamics.remove(e.body);
			// removePrisoner(e);
		}

		statics = [];
		
		level = l;
		
		worldMask.tile.scaleToSize(l.pxWid, l.pxHei);
		var m = colorFilter.matrix;
		var c = Vector.fromColor(level.f_Tint_int);
		m.identity();
		m.scale(c.x, c.y, c.z);

		if (physics == null) {
			physics = echo.Echo.start({
				width: level.pxWid,
				height: level.pxHei,
				gravity_y: 0,
				iterations: 2
			});
		}
		
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
		
		vaultOpen = false;

		bg.addChild(l.l_Tiles.render());

		for (v in l.l_Entities.all_Vault) {
			vault = hxd.Res.img.vault.toSprite(bg);
			vault.originX = vault.originY = 16;
			vault.animation.play("closed");
			vault.x = v.pixelX;
			vault.y = v.pixelY;
		
			vaultMaskContainer = new Bitmap(fg);
			vaultMask = new Bitmap(h2d.Tile.fromColor(0xffffff), vaultMaskContainer);
			vaultMask.tile.scaleToSize(game.s2d.width, vault.y + 14);
			vaultMaskContainer.filter = new h2d.filter.Mask(vaultMask);
		}

		fg.addChild(l.l_Foreground.render());
		
		safeZones = [];
		for (z in l.l_SafeZones.all_SafeZone) {
			var s = new SafeZone(safeZoneContainer);
			s.x = z.pixelX;
			s.y = z.pixelY;
			safeZones.push(s);
			safeZoneCount ++;
		}

		groundGraphics = new Graphics(bg);

		var armPos = l.l_Entities.all_ClockArm[0];
		if (armPos != null) {
			var face = new Bitmap(hxd.Res.img.clockface.toTile(), bg);
			face.tile.dx = face.tile.dy = -16;
			arm = new Bitmap(hxd.Res.img.clockarm.toTile(), face);
			arm.tile.dx = -2;
			arm.tile.dy = -2;
			
			face.x = armPos.pixelX;
			face.y = armPos.pixelY;
		}
		
		laser = new Laser(this, laserContainer);
		laser.onScanDone = onScanDone;
		
		if (isMenu) {
			sproing = hxd.Res.img.sproing.toSprite(bg);
			sproing.originX = 16;
			sproing.originY = 64 - 16;
			sproing.animation.play("idle");
		}
		
		if (player == null) {
			player = new Prisoner(Player, this);
		} else {
			player.reAddToScene();
			player.finishJump();
		}
		
		// player.damage ++;
		
		if (!isMenu) {
			player.fallFromCeiling();
		}

		player.controlled = true;
		var spawnPos = l.l_Entities.all_PlayerSpawn[0];
		player.setPos(spawnPos.pixelX, spawnPos.pixelY);
		dynamics.push(player.body);

		if (sproing != null) {
			sproing.x = spawnPos.pixelX;
			sproing.y = spawnPos.pixelY;
		}
		
		for (i in 0...level.f_Enemies) {
			spawnPrisoner();
		}
		
		for (i in 0...level.f_BigEnemies) {
			spawnPrisoner(BigEnemy);
		}

		for (i in 0...level.f_Judges) {
			var p = spawnPrisoner(Judge);
			var judgePos = level.l_Entities.all_JudgeSpawn[0];
			judge = p;
			p.setPos(judgePos.pixelX, judgePos.pixelY);
		}
		
		worldOffsetY.setImmediate(1); //game.s2d.height);
		worldOffsetY.value = 0;
		if (!isMenu) {
			game.sounds.playSound(hxd.Res.sound.hahh, 0.1);
		}
		
		if (level.f_FinalLevel) {
			var phrases = [
				"Huh! What are you doing here?!!\nI WILL END YOU",
				"How is this possible?! You're supposed to be a dead one!!",
				"I SHOULDN'T HAVE INSTALLED MY OFFICE ON THE GROUND FLOOR",
				"HOW?!?! I WILL CRUSH YOUR BONES AND SKELETON",
				"THIS ISNT POSSIBLE! You stupid little guy",
			];

			var sp = new SpeechBubble(phrases.randomElement(), null, judge, fg);
			sp.delay = 0.6;

			speechBubb = sp;
		}
		if (level.f_MenuLevel) {
			var phrases = [
				"For your crimes, I will sentence you to...",
				"I don't even care what you have done.\nI am sentencing you to...",
				"You are sentenced to...",
				"It is time for you to pay for your crimes. You are sentenced to...",
			];

			var sp = new SpeechBubble(phrases.randomElement(), null, judge, fg);
			sp.delay = 0.6;
			sp.charsPerSecond = 6;

			speechBubb = sp;
		}
		
		player.disableControls = isMenu;

		running = true;
	}
	
	var sproing: Sprite;
	
	var speechBubb: SpeechBubble = null;
	
	var flashed = false;
	public function onPrisonerScanFail(p: Prisoner) {
		if (p == player) {
			game.sounds.playWobble(hxd.Res.sound.scanfail, 0.4);
			musicChannel.fadeTo(0.3);
			if (!flashed) {
				flash(1);
			}
		}
	}
	
	var flashFrames = 0;
	var flashBm: Bitmap;
	public function flash(frames = 1) {
		flashed = true;
		flashBm.tile.scaleToSize(game.s2d.width, game.s2d.height);
		flashBm.visible = true;
		flashFrames = frames;
	}
	
	public function addScore(amount = 0) {
		
	}
	
	public function onPrisonerHurt(prisoner: Prisoner, attacker: Prisoner = null) {
		if (attacker == player) {
			score += 10;
			// showTextPopup(10, prisoner.x, prisoner.y - prisoner.data.Height * 0.5);
		}
		
		if (speechBubb != null && speechBubb.talker == prisoner) {
			speechBubb.hide();
			speechBubb = null;
		}
	}
	
	public function killPrisoner(p: Prisoner, killer: Prisoner = null) {
		dynamics.remove(p.body);
		prisoners.remove(p);
		
		if (killer == null && p.lastAttacker == player && time - p.lastHurtTime < 1.7) {
			var scr = Math.round(p.data.Score * 1.5);
			score += scr;
			showTextPopup(scr, p.x, p.y - p.data.Height * 0.5);

			if (!p.teethed) {
				p.teethed = true;
				spawnTooth(p.x, p.y, Std.int(p.data.Teeth * 1.2));
			}
		} else if (killer == player) {
			score += p.data.Score;
			showTextPopup(p.data.Score, p.x, p.y - p.data.Height * 0.5);
			if (!p.teethed) {
				p.teethed = true;
				spawnTooth(p.x, p.y, p.data.Teeth);
			}
		}

		if (p == player) {
			loseGame();
			if (!flashed) {
				flash();
			}
		}
		
		if (judge != null && p == judge && running) {
			winGame();
		}

		if (speechBubb != null && speechBubb.talker == p) {
			speechBubb.hide();
			speechBubb = null;
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
	
	public var fadeOut = new EasedFloat(1.0, 1.0);
	
	public var wonGame = false;
	public function winGame() {
		if (player.markedForDisintegration) {
			return;
		}
		
		if (player.state == Dead) {
			return;
		}

		if (wonGame) {
			return;
		}

		wonGame = true;
		running = false;

		var ch = musicChannel;
		musicChannel.fadeTo(0, 1, () -> musicChannel.stop());
		player.disableControls = true;
		timeout(1.8, () -> {
			//game.sounds.playSound(hxd.Res.sound.wingame, 0.4);
			timeScale.value = 1.0;
			timeout(1.0, () -> {
				var bm = new Bitmap(h2d.Tile.fromColor(0x333333), container);
				var t = new Text(hxd.Res.fonts.marumonica.toFont(), container);
				t.textAlign = Center;
				bm.x = -64;
				timeout(0.1, () -> {
					t.text = "JUSTICE SERVED";
					game.sounds.playWobble(hxd.Res.sound.reverseclick, 0.5);
					timeout(0.4, () -> {
						t.text += '\n - congratulations, you beat the game - ';
						game.sounds.playWobble(hxd.Res.sound.reverseclick, 0.5);
						t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);
						gameOverFlashEase.setImmediate(1);
						gameOverFlashEase.value = 0.;
					});

					t.x = Math.round(game.s2d.width * 0.5);
					t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);
					
					gameOverBm = bm;
					gameOverBmEase.value = 1.;
					gameOverFlashEase.value = 0.;

					bm.y = Math.round(game.s2d.height * 0.5);
					bm.x = t.x;
					bm.tile.scaleToSize(game.s2d.width + 128, t.textHeight * 4 + 37);
					bm.tile.setCenterRatio();

					new Timeout(1.25, () -> {
						t.text += "\n\nPress attack to play again";
						game.sounds.playWobble(hxd.Res.sound.reverseclick, 0.5);
						gameOverFlashEase.setImmediate(1);
						gameOverFlashEase.value = 0.;
						t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);
						canRestart = true;
					});
				});
			});
		});
	}
	
	var timeScale = new EasedFloat(1.0, 0.5);
	public function loseGame() {
		running = false;
		timeScale.setImmediate(0.5);
		musicChannel.fadeTo(0, 0.5);
	}

	var gameOverBm: Bitmap = null;
	var gameOverBmEase = new EasedFloat(0, 0.5);
	var gameOverFlashEase = new EasedFloat(1, 0.3);
	public function loseGameFinish() {
		musicChannel.stop();
		gameOverBmEase.easeFunction = elk.M.elasticOut;

		new Timeout(0.3, () -> {
			timeScale.value = 1.0;
			var bm = new Bitmap(h2d.Tile.fromColor(0x333333), container);
			var t = new Text(hxd.Res.fonts.marumonica.toFont(), container);
			t.textAlign = Center;
			bm.x = -64;
			new Timeout(0.4, () -> {
				var m = colorFilter.matrix;
				m.colorSaturate(-1);
				colorFilter.matrix = m;
				t.text = "DISINTEGRATED";
				t.text += '\n - reached floor ${levelIndex} - ';
				t.x = Math.round(game.s2d.width * 0.5);
				t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);
				game.sounds.playWobble(hxd.Res.sound.reverseclicknegative, 0.5);
				
				gameOverBm = bm;
				gameOverBmEase.value = 1.;
				gameOverFlashEase.value = 0.;

				bm.y = Math.round(game.s2d.height * 0.5);
				bm.x = t.x;
				bm.tile.scaleToSize(game.s2d.width + 128, t.textHeight * 2 + 37);
				bm.tile.setCenterRatio();

				new Timeout(0.65, () -> {
					t.text += "\n\nPress attack to try again";
					t.y = Math.round((game.s2d.height - t.textHeight) * 0.5);
					game.sounds.playWobble(hxd.Res.sound.reverseclicknegative, 0.5);

					//bm.y = Math.round(game.s2d.height * 0.5);
					//bm.tile.scaleToSize(game.s2d.width + 128, t.textHeight + 37);
					//bm.x = t.x;
					//bm.tile.scaleToSize(game.s2d.width + 128, t.textHeight + 37);
					//bm.tile.setCenterRatio();

					canRestart = true;
				});
			});
		});
	}
	
	public var canRestart = false;
	
	public function spawnPrisoner(type: CData.CharacterKind = Enemy) {
		var p = new Prisoner(type, this);
		var s = level.l_Entities.all_EnemySpawn[0];
		p.setPos(s.pixelX + s.width * Math.random(), s.pixelY + s.height * Math.random());
		dynamics.push(p.body);
		return p;
	}
	
	public var vaultOpen = false;
	public function openVault() {
		if (vaultOpen) return;
		if (vault == null) return;
		vaultOpen = true;
		vault.animation.play("opening", false);
		game.sounds.playSound(hxd.Res.sound.vaultopen, 0.6);
		vault.animation.onEnd = s -> {
			vault.animation.play("opened");
		}
	}
	
	public function jumpIntoPit(prisoner: Prisoner) {
		if (vault == null) return;

		if (prisoner.state != Jumping && prisoner.state != Dead) {
			prisoner.jump(vault.x);
			game.sounds.playWobble(hxd.Res.sound.jump, 0.5);
			vaultMaskContainer.addChild(prisoner.sprite);
			if (prisoner == player) {
				player.lives ++;
				if (player.lives > 36) {
					player.lives = 36;
				}
				running = false;
				score += 500;
				showTextPopup(500, player.x, player.y - player.data.Height * 0.5);
				timeout(1.2, () -> loadNextLevel());
			}
		}
	}
	
	function timeout(duration: Float, call: Void -> Void) {
		new Timeout(duration, () -> {
			if (game.states.current == this) {
				call();
			}
		});
	}
	
	function onScanDone() {
		var aliveZones = 0;
		for (s in safeZones) {
			if (s.isActive) {
				aliveZones ++;
			}
		}

		if (aliveZones == 0) {
			//openVault();
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
	var totalIntervalsBeaten = 0;
	function intervalComplete() {
		if (wonGame) {
			return;
		}

		intervalsBeaten ++;
		totalIntervalsBeaten ++;
		if (!isMenu) {
			laser.startScan();
		}
	}
	
	var ticked = false;
	function passTime(dt: Float) {
		secondProgress += dt;
		if (wonGame) {
			return;
		}

		if (secondProgress >= 1) {
			secondProgress -= 1;
			currentSecond ++;
			ticked = !ticked;
			if (!wonGame) {
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
			}
			if (currentSecond >= interval) {
				currentSecond = 0;
				intervalComplete();
			}
			armRotation.value = (intervalsBeaten + currentSecond / interval) * Math.PI * 2 - Math.PI * 0.5;
		}

		timeUntilScan = interval - (secondProgress + currentSecond);
	}
	
	public var running = true;
	
	var sproinged = false;
	var verdictShown = false;
	function showVerdict() {
		if (verdictShown) return;
		verdictShown = true;
		var phrases = [
			"Near Death!",
			"Life in The Death Tower!",
			"Eternal Suffering!",
			"A terrible time!",
		];

		var sp = new SpeechBubble(phrases.randomElement(), null, judge, fg);
		sp.delay = 0.1;
		sp.charsPerSecond = 6;

		speechBubb = sp;
		timeout(0.4, finishMenu);
	}
	
	var menuFinished = false;
	function finishMenu() {
		if (menuFinished) return;
		menuFinished = true;

		timeout(1.0, () -> worldOffsetY.value = 1);
		timeout(2.0, () -> {
			game.sounds.playSound(hxd.Res.sound.swoosh, 0.1);
			loadNextLevel(true);
		});
	}

	public function menuAction() {
		if (verdictShown) {
			finishMenu();
			return;
		}

		if (sproinged) {
			showVerdict();
			return;
		}

		if (speechBubb.isDone){ 
			sproing.animation.play("bounce", false);
			game.sounds.playWobble(hxd.Res.sound.sproing);
			player.jumpVel = -25;
			player.falling = true;
			speechBubb.hide();
			sproinged = true;
			timeout(0.4, showVerdict);
		} else {
			speechBubb.finish();
		}
	}

	override function tick(dt:Float) {
		super.tick(dt);
		if (running && !isMenu) {
			time += dt;
		}
		
		if (isMenu) {
			if (controls.isPressed(Attack)) {
				menuAction();
			}
		}
		
		playTimeText.text = time.toTimeString();
		scoreText.text = Std.int(scoreEased.value).toMoneyString();
		// toothText.text = teeth.toMoneyString();

		passTime(dt);
		arm.rotation = armRotation.value;

		for (e in actors) {
			e.preTick();
		}

		for (e in actors) {
			e.tick(dt);
		}
		
		var ll = toothArray.length;
		for (i in 0...toothArray.length) {
			var t = toothArray[ll - 1 - i];
			if (t == null) break;
			if (t.done) {
				t.remove();
				toothArray.remove(t);
				score += 100;
				game.sounds.playWobble(hxd.Res.sound.pickup, 0.2);
			}
		}

		for (t in toothArray) {
			t.tick(dt, player.x, player.y - 8);
		}

		if (flashFrames >= 0) {
			flashFrames --;
			if (flashFrames < 0) {
				flashBm.visible = false;
			}
		}
		
		for (t in cachedTexts) {
			if (t.untilFade > 0) {
				t.untilFade -= dt;
				t.txt.visible = true;
				if (t.untilFade <= 0) {
					t.txt.visible = false;
				}
			}
		}
		
		#if debug
		if (hxd.Key.isPressed(hxd.Key.P)) {
			secondProgress = 7;
		}
		if (hxd.Key.isPressed(hxd.Key.L)) {
			loadNextLevel();
		}
		if (hxd.Key.isPressed(hxd.Key.I)) {
			jumpIntoPit(player);
		}
		if (hxd.Key.isPressed(hxd.Key.N)) {
			winGame();
		}
		#end
		
		if (vault != null && vaultOpen) {
			if (vault.animation.currentFrameIndex > 4)  {
				for (p in prisoners) {
					if (!laser.failedPrisoners.contains(p)) {
						var dx = p.x - vault.x;
						var dy = p.y - vault.y;
						if (Math.abs(dx) < 20 && Math.abs(dy) < 20) {
							jumpIntoPit(p);
						}
					}
				}
			}
		}
		
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
		
		safeZoneCount = 0;
		for (s in safeZones) {
			if (s.isActive) {
				safeZoneCount ++;
			}
		}

		updateCamBounds();
	}
	
	public function findViableTarget(t: Prisoner): Prisoner {
		var desperate = safeZoneCount * 4 <= prisoners.length || safeZoneCount <= 0;

		var closest: Prisoner = null;
		var closestDist = Math.POSITIVE_INFINITY;
		var highestAggro = 0.;
		
		if (prisoners.length <= 2) {
			desperate = true;
		}

		if (t.rage > Math.random()) {
			desperate = true;
		}

		for (p in prisoners) {
			if (p == t) continue;
			var dx = t.x - p.x;
			var dy = t.y - p.y;
			var dSq = dx * dx + dy * dy;

			var maxDistSq = p.aggroLevel * p.aggroRadiusPerLevel;
			maxDistSq *= maxDistSq;

			if (desperate) {
				maxDistSq = Math.POSITIVE_INFINITY;
			}

			if (dSq < closestDist && dSq < maxDistSq) {
				closestDist = dSq;
				closest = p;
				highestAggro = p.aggroLevel;
			}
		}

		return closest;
	}
	
	public function findTarget(attacker: Prisoner, dirX = 1., count = 1): Array<Prisoner> {
		var d = new Point();
		var d2 = new Point(dirX, 0);
		
		var res = [];

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
				res.push(p);
				if (res.length >= count) {
					break;
				}
			}
		}
		
		return res;
	}
	
	override function update(dt: Float) {
		super.update(dt);
		game.timeScale = timeScale.value;
		
		for (e in actors) {
			e.render();
		}
		
		groundGraphics.clear();
		groundGraphics.lineStyle(1, 0xde5353, 0.5);
		for (p in prisoners) {
			if (p.state == Jumping || p.state == Dead) {
				continue;
			}

			var r = Math.round(p.aggroLevel * p.aggroRadiusPerLevel);
			if (r > 2) {
				groundGraphics.drawCircle(p.sprite.x, p.sprite.y, r);
			}
		}
		
		characterLayer.ysort(0);
		
		if (level != null) {
			var w = Math.round((game.s2d.width - level.pxWid) * 0.5);
			var h = Math.round((game.s2d.width - level.pxWid) * 0.5 + worldOffsetY.value * game.s2d.height);

			world.x = w;
			world.y = h;
		}

		world.alpha = (1 - Math.abs(worldOffsetY.value));

		var sfAlpha = (timeUntilScan < checkTime || laser.scanning) ? 1.0 : 0.1;
		for (s in safeZones) {
			if (s.isActive) {
				s.alpha = sfAlpha;
			} else {
				s.alpha *= 0.98;
			}
		}

		if (gameOverBm != null) {
			gameOverBm.rotation = -Math.PI * 0.01 * gameOverBmEase.value;
			var v = gameOverFlashEase.value * 1000;
			gameOverBm.color.set(v, v, v);
			gameOverBm.alpha = 0.8 + gameOverFlashEase.value * 0.2;
		}
		
		container.alpha = fadeOut.value;
		uiContainer.visible = !isMenu;
	}
}
