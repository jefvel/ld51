package entities;

import gamestates.PlayState;
import h2d.Bitmap;

class Laser extends Actor {
	public var scanTime = 0.;
	var totalScanTime = 0.6;
	var scanning = false;
	var laser: Bitmap;

	var scanned: Array<Prisoner> = [];
	var state: PlayState = null;
	
	var failedPrisoners: Array<Prisoner> = [];

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
		failedPrisoners = [];
	}
	
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
					
					scanned.push(p);
					
					if (state.inSafeZone(p.x, p.y)) {
						trace("prisoner is safe");
						p.flashGreen();
					} else {
						failedPrisoners.push(p);
						trace("Prisoner is no good");
					}
				}
			}
			
			if (scanTime >= totalScanTime) {
				scanning = false;
			}
		}
	}
}