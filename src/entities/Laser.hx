package entities;

import gamestates.PlayState;
import h2d.Bitmap;

class Laser extends Actor {
	public var scanTime = 0.;
	var totalScanTime = 0.6;
	public var scanning = false;
	var laser: Bitmap;

	var scanned: Array<Prisoner> = [];
	var state: PlayState = null;
	
	var failedPrisoners: Array<Prisoner> = [];
	public var onScanDone : Void -> Void;

	public function new(state: PlayState, ?p) {
		this.state = state;
		super(state);
		laser = new Bitmap(hxd.Res.img.laser.toTile(), p);
		laser.tile.dx = -16;
	}

	public function startScan() {
		scanning = true;
		scanTime = 0;
		scanned = [];
		untilNextFail = 0.4;
		state.game.sounds.playWobble(hxd.Res.sound.scan, 0.2);
		exhaustedZones = [];
	}
	
	var exhaustedZones: Array<entities.SafeZone> = [];
	
	override function tick(dt:Float) {
		super.tick(dt);

		if (scanning) {
			scanTime += dt;
			var xx = Math.round(laser.getScene().width * (scanTime / totalScanTime));
			laser.x = xx;
			
			for (p in state.prisoners) {
				if (p.x < laser.x) {
					if (scanned.contains(p)) {
						continue;
					}
					
					// Jumping guys can't be hurt
					if (p.state == Jumping) {
						continue;
					}
					
					scanned.push(p);
					
					var zone = state.inSafeZone(p.x, p.y);
					if (zone != null) {
						p.flashGreen();
						exhaustedZones.push(zone);
					} else {
						failedPrisoners.push(p);
					}
				}
			}
			
			if (scanTime >= totalScanTime) {
				scanning = false;
				var z = exhaustedZones.randomElement();
				if (z != null) {
					z.isActive = false;
				}
				if (onScanDone != null) {
					onScanDone();
				}
			}
		} else {
			if (failedPrisoners.length > 0) {
				untilNextFail -= dt;
				if (untilNextFail < 0) {
					untilNextFail = 0.1;
					var p = failedPrisoners.shift();
					if (p.state != Jumping) {
						p.disintegrate();
					}
				}
			}
		}
	}
	var untilNextFail = 0.1;
}