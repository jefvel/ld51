package entities;

import h2d.Object;

class Texts extends Object{
	public function new(title: String, subtitle: String, ?p) {
		super(p);
	}
} 

class Upgrades extends Object {
	var upgradeLevels: Map<CData.UpgradesKind, Int> = new Map();
	var left: Texts;
	var right: Texts;
	var input = Controls.instance;

	function showUpgrades() {
		var upgrades = CData.upgrades.all.toArrayCopy();
	}
	
	public function chooseRight() {
	}
	
	public function chooseLeft() {

	}

	public function tick(dt: Float) {
		
	}
}