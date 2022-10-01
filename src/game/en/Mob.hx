package en;

class Mob extends Entity {
	public static var ALL : FixedArray<Mob> = new FixedArray(40);
	var data : Entity_Mob;

	public function new(d) {
		data = d;
		super();
		useLdtkEntity(data);
		ALL.push(this);
		initLife(data.f_hp);
		circularWeightBase = 5;
		circularRadius = 7;

		spr.set(Assets.entities);
		outline.color = Assets.red();

		spr.anim.registerStateAnim(D.ent.mFly, 10.2, ()->!onGround);
		spr.anim.registerStateAnim(D.ent.mLay, 10.1, ()->hasAffect(LayDown) || !isAlive());
		spr.anim.registerStateAnim(D.ent.mStun, 10.0, ()->hasAffect(Stun));

		spr.anim.registerStateAnim(D.ent.mPunch_charge, 2, ()->isChargingAction("punch"));

		spr.anim.registerStateAnim(D.ent.mWalk, 1, ()->isMoving());

		spr.anim.registerStateAnim(D.ent.mIdle, 0);
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		super.hit(dmg, from);
		setSquashX(0.4);
		blink(dmg==0 ? White : Red);
		if( !isChargingAction() )
			spr.anim.playOverlap(D.ent.mHit);
	}

	override function onDie() {
		super.onDie();
		outline.enable = false;
		circularWeightBase = 0;
	}

	override function setAffectS(k:Affect, t:Float, allowLower:Bool = false) {
		if( isChargingAction() )
			return;

		super.setAffectS(k, t, allowLower);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onLand() {
		super.onLand();

		cd.unset("pushOthers");
		camera.shakeS(0.3, 0.2);
		setSquashX(0.7);

		if( hasAffect(Stun) ) {
			setAffectS(LayDown, 0.5);
			setAffectS(Stun, getAffectRemainingS(Stun)+getAffectRemainingS(LayDown));
		}

		if( !cd.has("landBumpLimit") ) {
			cd.setS("landBumpLimit",1.5);
			dz = 0.12;
		}
	}

	override function canMoveToTarget():Bool {
		return super.canMoveToTarget() && !aiLocked();
	}

	inline function aiLocked() {
		return !isAlive() || hasAffect(Stun) || hasAffect(LayDown) || isChargingAction() || cd.has("aiLock");
	}

	inline function lockAiS(t:Float) {
		cd.setS("aiLock",t,false);
	}

	override function onTouch(e:Entity) {
		super.onTouch(e);
		if( e.is(en.Mob) && e.isAlive() && cd.has("pushOthers") ) {
			if( !onGround && e.onGround && ( hasAffect(Stun) || !isAlive() ) && !e.cd.has("mobBumpLock") ) {
				setAffectS(Stun, 1);
				e.bumpAwayFrom(this, 0.3);
				e.setAffectS(Stun, 0.6);
				e.dz = rnd(0.15,0.2);
				e.cd.setS("pushOthers",0.5);
				e.cd.setS("mobBumpLock",0.2);
			}
		}

	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// if( isChargingAction("punch") && hasAffect(Stun) ) {
		// 	cancelAction();
		// }

		if( !aiLocked() ) {
			dir = dirTo(hero);
			goto(hero.attachX, hero.attachY);

			if( distPx(hero)<=Const.GRID*1.2 ) {
				chargeAction("punch", 0.7, ()->{
					lockAiS(0.5);
					spr.anim.playOverlap(D.ent.mPunch_hit);
				});
			}
		}
	}

}