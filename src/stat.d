import util;
import ser;

// XXX: Perhaps this should be renamed to something clearer, i.e.
// `StatIndex`.
enum Stat
{
	none = -1,
	// The attributes.
	attributes_min,
		strength = attributes_min,
		dexterity,
		agility,
		endurance,
		reflex,
		observantness,
		intelligence,
	attributes_max = intelligence,

	// The technical skills.
	technical_skills_min,
		constructing = technical_skills_min,
		repairing,
		modding,
		hacking,
	technical_skills_max = hacking,

	// The combat skills.
	combat_skills_min,
		striking = combat_skills_min,
		aiming,
		extrapolating,
		throwing,
		dodging,
	combat_skills_max = dodging,

	// The knowledges.
	knowledges_min,
		ballistics = knowledges_min,
		explosives,
		lasers,
		plasma,
		electromagnetism,
		computers,
	knowledges_max = computers,
}

struct Stats
{
	mixin (serializable);
	mixin SimplySerialized;
	enum attribute_min = -5;
	enum attribute_max = 5;
	enum skill_min = 0;
	enum skill_max = 5;
	enum knowledge_min = 0;
	enum knowledge_max = 5;
	enum names = [
		Stat.strength: "strength",
		Stat.dexterity: "dexterity",
		Stat.agility: "agility",
		Stat.endurance: "endurance",
		Stat.reflex: "reflex",
		Stat.observantness: "observantness",
		Stat.intelligence: "intelligence",
		Stat.constructing: "constructing",
		Stat.repairing: "repairing",
		Stat.modding: "modding",
		Stat.hacking: "hacking",
		Stat.striking: "striking",
		Stat.aiming: "aiming",
		Stat.extrapolating: "extrapolating",
		Stat.throwing: "throwing",
		Stat.dodging: "dodging",
		Stat.ballistics: "ballistics",
		Stat.explosives: "explosives",
		Stat.lasers: "lasers",
		Stat.plasma: "plasma",
		Stat.electromagnetism: "electromagnetism",
		Stat.computers: "computers",
	];
	int[Stat.max+1] stats; // All 0 by default.
	alias stats this;

	this(Serializer serializer) {}

	string toString(Stat stat)
	{
		if (stat >= Stat.attributes_min
		&& stat <= Stat.attributes_max) {
			return val_to_minus_5_to_5_adjective[stats[stat]]
				~" "~names[stat];
		} else if ((stat >= Stat.technical_skills_min
		&& stat <= Stat.technical_skills_max)
		|| (stat >= Stat.combat_skills_min
		&& stat <= Stat.combat_skills_max)
		|| (stat >= Stat.knowledges_min
		&& stat <= Stat.knowledges_max)) {
			return val_to_0_to_5_adjective[stats[stat]]~" "~names[stat];
		}
		assert(false);
	}

	bool trySet(Stat stat, int val)
	{
		if (stat >= Stat.attributes_min
		&& stat <= Stat.attributes_max) {
			if (val > attribute_max || val < attribute_min) {
				return false;
			}
		} else if ((stat >= Stat.technical_skills_min
		&& stat <= Stat.technical_skills_max)
		|| (stat >= Stat.combat_skills_min
		&& stat <= Stat.combat_skills_max)) {
			if (val > skill_max || val < skill_min) {
				return false;
			}
		} else if (stat >= Stat.knowledges_min
		&& stat <= Stat.knowledges_max) {
			if (val > knowledge_max || val < knowledge_min) {
				return false;
			}
		} else {
			assert(false);
		}
		stats[stat] = val;
		return true;
	}
}

