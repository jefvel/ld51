package entities;

import h2d.Bitmap;


class Tooth extends Bitmap {
	public var t = 0.;
	var vx = 0.;
	var vy = 0.;
	
	var bt = 0.;
	var totalBounce = 0.9;
	public var px = 0.;
	public var py = 0.;
	
	public function new(?p) {
		super(hxd.Res.img.tooth.toTile(),p);
		tile.setCenterRatio();
		totalBounce += Math.random() * 0.2;
		vx = Math.random() - 0.5;
		vy = Math.random() - 0.5;
	}
	
	public function tick(dt: Float, targetX: Float, targetY : Float) {
		if (bt < totalBounce) {
			bt += dt;
		} else {
			t += dt;
			var tt = hxd.Math.clamp(t / 0.6);
			var time = elk.M.elasticOut(tt);

			var dx = (targetX - x);
			var dy = (targetY - y);
			vx = dx * time;
			vy = dy * time;
			done = tt >= 1;
		}
		
		px += vx;
		py += vy;
		vx *= 0.92;
		vy *= 0.92;
		
		x = px;
		y = py + elk.M.bounceOut(hxd.Math.clamp(bt / totalBounce * 4)) * 8;
	}

	public var done = false;
}