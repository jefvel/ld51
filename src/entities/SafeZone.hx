package entities;

import h2d.Bitmap;

class SafeZone extends Bitmap {
	public var isActive = true;
	
	public var cx = 0.;
	public var cy = 0.;
	
	public function new(?p) {
		super(hxd.Res.img.safezone.toTile(), p);
		width = height = 32;
		tile.dx = tile.dy = -16;
	}
}