package entities;

import h2d.Bitmap;

class SafeZone extends Bitmap {
	public var isActive = true;
	
	public function new(?p) {
		super(hxd.Res.img.safezone.toTile(), p);
		width = height = 32;
	}
}