import 'dart:math';
import 'dart:mirrors';
//import 'package:args/args.dart';
// Global variables
final CLASSES = [Barbarian, Bard, Cleric, Druid, Fighter_Arch,Fighter_Melee,
                 Monk, Paladin, Ranger, Rogue, Sorcerer, Warlock, Wizard];

final Map RACES = {
  "Dwarf": {"Con":2},
  "Elf": {"Dex":2},
  "Halfling": {"Dex":2},
  "Human": {"Str":1,"Dex":1,"Con":1,"Int":1,"Cha":1,"Wis":1},
  "Dragonborn": {"Str":2,"Cha":1},
  "Gnome": {"Int":1},
  "Half-Elf": {"Cha":2,"Dex":1,"Int":1},
  "Half-Orc": {"Str":2,"Con":1},
  "Tiefling": {"Int":1,"Cha":2}
};

final Map clsmap = {
  "barbarian": Barbarian,
  "bard": Bard,
  "cleric": Cleric,
  "druid": Druid,
  "fighter": getRand([Fighter_Arch,Fighter_Melee]),
  "monk": Monk,
  "paladin": Paladin,
  "ranger": Ranger,
  "rogue": Rogue,
  "sorcerer": Sorcerer,
  "warlock": Warlock,
  "wizard": Wizard
};

final List race_list = ["Dwarf","Elf","Halfling","Human","Dragonborn",
                        "Gnome","Half-Elf","Half-Orc","Tiefling"];

String lb = "\n";
var sel_class = null;
var sel_name = null;
var sel_race = null;

// Global functions

// returns a random element from the supplied array
getRand(ary) {
  var aryrng = new Random();
  return ary[aryrng.nextInt(ary.length)];
}

// rolls a y-sided die x times and returns an array of the results
List xdy(x, y) {
  List ary = [];
  var dice_rng = new Random();
  for (var i = 0; i < x; i++) {
	  ary.add(dice_rng.nextInt(y) + 1);
  }
  return ary;
}

// rolls a y-sided die x times (using xdy)
// drops the lowest result, then returns the rest in an array
List xdyDrop(x, y, d) {
  List ary = xdy(x,y);
  ary.sort((a,b) => b.compareTo(a));
  ary = ary.take(ary.length-d);
  return ary;
}

class Character {
  // Parent class for D&D classes

  // Class variables
  var rng = new Random();
  String name = "";
  String class_name = "";
  Map stats = {
    "Str": 0,
    "Dex": 0,
    "Con": 0,
    "Int": 0,
    "Wis": 0,
    "Cha": 0
  };
  Map stat_weights = {};
  String race = "";
  num hit_die = 0;
  num hit_points = 0;
  List skills = [];
  List proficiencies = [];
  List abilities = [];
  List equipment = [];
  String background = "";
  List saves = [];
  List potential_skills = [];
  num skill_num = 0;
  num wealth = 0;


  // Get skill names with self.SKILLS[n]
  final SKILLS = ["Athletics", //0
                  "Acrobatics", //1
                  "Sleight of Hand", //2
                  "Stealth", //3
                  "Arcana", //4
                  "History", //5
                  "Investigation", //6
                  "Nature", //7
                  "Religion", //8
                  "Animal Handling", //9
                  "Insight", //10
                  "Medicine", //11
                  "Perception", //12
                  "Survival", //13
                  "Deception", //14
                  "Intimidation", //15
                  "Performance", //16
                  "Persuasion" //17
                ];

  // no-args constructor
  Character() {
    if (sel_name == null) {
      name = rName();
    } else {
      name = sel_name;
    }
    if (sel_race == null) {
      race = getRand(race_list);
    } else {
      race = sel_race;
    }
  }

  // adds race-based modifiers to the character's statistics
  void statMod(cls) {
    var mods = RACES[cls];
    mods.forEach((stat,modifier) {
      this.stats[stat] = this.stats[stat] + modifier;
    });
  }

  // generates a random name between 5 and 9 characters long
  // picks randomly between a vowel and a consonant to start, then
  // alternates vowels with consonants
  String rName() {
    var vowels = ["a","e","i","o","u","w","y"];
    var consonants = ["b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","z"];
    var ln = this.rng.nextInt(5) + 4;
    var nm = "";
    var toggle = this.rng.nextInt(2) == 1 ? true : false;
    for (var i = 0; i < ln; i++) {
      if (toggle) {
        nm += getRand(consonants);
      } else {
        nm += getRand(vowels);
      }
      toggle = !toggle;
    }
    return nm.replaceRange(0,1,nm[0].toUpperCase());
  }

  // Generates stats for the character
  // Rolls 4d6, drops the lowest, sums the result; repeats 6 times
  List getStats() {
    List local_stats = [];
    for (var j = 0; j < 6; j++) {
      local_stats.add(xdyDrop(4,6,1).fold(0, (prev, el) => prev + el));
    }
    local_stats.sort();
    return local_stats;
  }

  // Assigns stats based on the generated class's stat priority
  // If a list of stats is passed in, use that; otherwise use getStats
  void assignStats([List rs]) {
    var raw_stats = rs == null ? getStats() : rs;
    raw_stats.sort();
    stat_weights.forEach((nm,wgt) {
      this.stats[nm] = raw_stats[wgt-1];
    });
  }

  // Picks random skills from the class's skill list
  // If a list of potential skills is passed in, use that;
  // otherwise use the default
  // If a number of skills to pick is passed in, use that;
  // otherwise use the default
  List assignSkills([List ps, num ns]) {
    var pskills = ps == null ? potential_skills : ps;
    var nskills = ns == null ? skill_num : ns;
    List final_skills = [];
    for (var i = 0; i < nskills; i++) {
      var cskill = getRand(pskills);
      final_skills.add(SKILLS[cskill]);
      pskills.remove(cskill);
    }
    return final_skills;
  }

  // Get character starting gold (xd4 * 1 for monks, xd4 * 10 for others)
  num getGold(num num_dice, num multiplier) {
    return xdy(num_dice,4).fold(0,(prev, el) => prev + el) * multiplier;
  }

  // Print a digest of the character
  // $lb is the line break; \n by default, %r optionally
  String toString() {
    String output = "";
    output += "$name - $race $class_name 1$lb";
    output += "Background: $background$lb";
    stats.forEach((nm, score) => output += "$nm: $score$lb");
    output += "$hit_points HP$lb";
    Map their_stuff = {
      "Saving throws" : saves,
      "Skills"        : skills,
      "Proficiencies" : proficiencies,
      "Abilities"     : abilities,
      "Equipment"     : equipment,
    };
    their_stuff.forEach((k,v) {
      output += k + ": " + v.join(", ") + "$lb";
    });
    output += "Gold: $wealth";
    return output;
  }
  void print_it() {
    print(this.toString());
  }
}

class Barbarian extends Character {
  Map stat_weights = {
    "Str": 6,
    "Dex": 4,
    "Con": 5,
    "Int": 1,
    "Wis": 2,
    "Cha": 3
  };

  Barbarian(){
    class_name = "Barbarian";
    assignStats();
    statMod(race);
    hit_die = 12;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Str","Con"];
    equipment = [getRand(["Greataxe","Martial melee weapon"]),
                 getRand(["Handaxe * 2","Simple weapon"]),
                 "Explorer's pack", "Javelin * 4"];
    potential_skills = [9, 0, 15, 7, 12, 13];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Light armor","Medium armor","Shields",
                      "Simple weapons","Martial weapons"];
    abilities = ["Rage"];
    background = "Outlander";
    wealth = getGold(2,10);
    this.print_it();
  }
}

class Bard extends Character {
  Map stat_weights = {
    "Str": 1,
    "Dex": 5,
    "Con": 2,
    "Int": 4,
    "Wis": 3,
    "Cha": 6
  };

  Bard(){
    class_name = "Bard";
    assignStats();
    statMod(race);
    hit_die = 8;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Dex","Cha"];
    equipment = [getRand(["Rapier","Longsword","Simple weapon"]),
                 getRand(["Diplomat's pack","Entertainer's pack"]),
                 getRand(["Lute","Musical instrument"]),
                 "Leather armor", "Dagger"];
    potential_skills = new List<int>.generate(SKILLS.length, (i) => i);
    skill_num = 3;
    skills = assignSkills();
    proficiencies = ["Light armor","Simple weapons","Hand crossbows",
                     "Longswords","Rapiers","Shortswords"];
    abilities = ["Cantrips * 2","Spells * 4"];
    background = "Entertainer";
    wealth = getGold(5,10);
    this.print_it();
  }
}

class Cleric extends Character {
  Map stat_weights = {
    "Str": 4,
    "Dex": 1,
    "Con": 5,
    "Int": 3,
    "Wis": 6,
    "Cha": 2
  };
  final DOMAINS = ["Knowledge", "Life", "Light", "Nature",
                   "Tempest", "Trickery", "War"];

  Cleric(){
    class_name = "Cleric";
    assignStats();
    statMod(race);
    hit_die = 8;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Wis","Cha"];
    equipment = ["Mace",getRand(["Scale mail","Leather Armor"]),
                  getRand([["Light Crossbow","Bolts * 20"],"Simple weapon"]),
                  getRand(["Priest's pack","Explorer's pack"]),
                  "Shield", "Holy symbol"];
    potential_skills = [5, 10, 11, 17, 8];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Light armor","Medium armor","Shields",
                      "Simple weapons"];
    abilities = ["Domain: " + getRand(DOMAINS),
                 "Cantrips * 3", "Spells"];
    background = "Acolyte";
    wealth = getGold(5,10);
    this.print_it();
  }
}

class Druid extends Character {
  Map stat_weights = {
    "Str": 2,
    "Dex": 3,
    "Con": 5,
    "Int": 4,
    "Wis": 6,
    "Cha": 1
  };

  Druid(){
    class_name = "Druid";
    assignStats();
    statMod(race);
    hit_die = 8;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Wis","Int"];
    equipment = ["Herbalism kit", getRand(["Wooden shield","Simple weapon"]),
                 getRand(["Scimitar","Melee weapon"]), "Leather armor",
                 "Explorer's pack", "Druidic focus"];
    potential_skills = [4, 9, 10, 11, 7, 12, 8, 13];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Light armor","Medium armor","Shields",
                      "Clubs","Daggers","Darts","Javelins","Maces",
                      "Quarterstaves","Scimitars","Sickles","Slings","Spears"];
    abilities = ["Druidic language", "Cantrips * 2", "Spells"];
    background = "Hermit";
    wealth = getGold(2,10);
    this.print_it();
  }
}

class Fighter_Arch extends Character {
  Map stat_weights = {
    "Str": 4,
    "Dex": 6,
    "Con": 4,
    "Int": 2,
    "Wis": 3,
    "Cha": 1
  };

  Fighter_Arch(){
    class_name = "Fighter";
    assignStats();
    statMod(race);
    hit_die = 10;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Str","Con"];
    equipment = ["Leather armor","Longbow","Arrow * 20","Martial weapon",
                  "Martial weapon","Handaxe * 2",
                  getRand(["Dungeoneer's pack","Explorer's pack"])];
    potential_skills = [9, 1, 0, 5, 10, 15, 12, 13];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["All armor","Shields","Simple weapons","Martial weapons"];
    abilities = ["Fighting Style: Archery","Second Wind"];
    background = "Soldier";
    wealth = getGold(5,10);
    this.print_it();
  }
}

class Fighter_Melee extends Character {
  Map stat_weights = {
    "Str": 6,
    "Dex": 4,
    "Con": 5,
    "Int": 3,
    "Wis": 2,
    "Cha": 1
  };

  final FIGHTING_STYLES = ["Defense","Dueling","Great Weapon Fighting",
                           "Protection","Two-Weapon Fighting"];

  Fighter_Melee(){
    class_name = "Fighter";
    assignStats();
    statMod(race);
    hit_die = 10;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Str","Con"];
    equipment = ["Chain mail","Martial weapon","Shield","Light crossbow",
                  "Bolts * 20",getRand(["Dungeoneer's pack","Explorer's pack"])];
    potential_skills = [9, 1, 0, 5, 10, 15, 12, 13];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["All armor","Shields","Simple weapons","Martial weapons"];
    abilities = ["Fighting Style: " + getRand(FIGHTING_STYLES),"Second Wind"];
    background = "Soldier";
    wealth = getGold(5,10);
    this.print_it();
  }
}

class Monk extends Character {
  Map stat_weights = {
    "Str": 3,
    "Dex": 6,
    "Con": 4,
    "Int": 2,
    "Wis": 5,
    "Cha": 1
  };

  Monk(){
    class_name = "Monk";
    assignStats();
    statMod(race);
    hit_die = 8;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Str","Dex"];
    equipment = [getRand(["Artisan's tools","Musical instrument"]),
                  getRand(["Shortsword","Simple weapon"]),
                  getRand(["Dungeoneer's pack","Explorer's pack"]),
                  "Darts * 10"];
    potential_skills = [1, 0, 5, 10, 8, 3];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Simple weapons","Short swords"];
    abilities = ["Unarmored Defense","Martial Arts"];
    background = "Hermit";
    wealth = getGold(5,1);
    this.print_it();
  }
}

class Paladin extends Character {
  Map stat_weights = {
    "Str": 6,
    "Dex": 2,
    "Con": 4,
    "Int": 1,
    "Wis": 3,
    "Cha": 5
  };

  Paladin(){
    class_name = "Paladin";
    assignStats();
    statMod(race);
    hit_die = 10;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Wis","Cha"];
    equipment = ["Martial weapon",getRand(["Martial weapon","Shield"]),
                  getRand(["Javelin * 5","Simple melee weapon"]),
                  getRand(["Priest's pack","Explorer's pack"]),
                  "Chain mail","Holy symbol"];
    potential_skills = [0, 10, 15, 11, 17, 8];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["All armor","Shields","Simple weapons","Martial weapons"];
    abilities = ["Divine Sense","Lay on Hands"];
    background = "Noble";
    wealth = getGold(5,10);
    this.print_it();
  }
}

class Ranger extends Character {
  Map stat_weights = {
    "Str": 4,
    "Dex": 6,
    "Con": 3,
    "Int": 2,
    "Wis": 5,
    "Cha": 1
  };

  final FAVORED_ENEMIES = ["Aberrations","Beasts","Celestials","Constructs",
                           "Dragons","Elementals","Fey","Fiends","Giants",
                           "Monstrosities","Oozes","Plants","Undead",
                           "Humanoids * 2"];
  final FAVORED_TERRAINS = ["Arctic","Coast","Desert","Forest","Grassland",
                            "Mountain","Swamp","The Underdark","Underwater"];

  Ranger(){
    class_name = "Ranger";
    assignStats();
    statMod(race);
    hit_die = 10;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Str","Dex"];
    equipment = [getRand(["Scale mail","Leather armor"]),
                  getRand(["Shortsword * 2","Simple weapon * 2"]),
                  getRand(["Dungeoneer's pack","Explorer's pack"]),
                  "Longbow","Arrows * 20"];
    potential_skills = [9, 0, 10, 6, 7, 12, 3, 13];
    skill_num = 3;
    skills = assignSkills();
    proficiencies = ["Light armor","Medium armor","Shields","Simple weapons",
                      "Martial weapons"];
    abilities = ["Favored Enemy: " + getRand(FAVORED_ENEMIES),
                  "Natural Explorer",
                  "Favored Terrain: " + getRand(FAVORED_TERRAINS)];
    background = "Outlander";
    wealth = getGold(5,10);
    this.print_it();
  }
}

class Rogue extends Character {
  Map stat_weights = {
    "Str": 2,
    "Dex": 6,
    "Con": 3,
    "Int": 5,
    "Wis": 1,
    "Cha": 4
  };

  Rogue(){
    class_name = "Rogue";
    assignStats();
    statMod(race);
    hit_die = 8;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Int","Dex"];
    equipment = [getRand(["Rapier","Shortsword"]),
                  getRand([["Shortbow","Arrows * 20"],"Shortsword"]),
                  getRand(["Burglar's pack","Dungeoneer's pack","Explorer's pack"]),
                  "Leather Armor","Dagger","Dagger","Thieves' tools"];
    potential_skills = [1, 0, 14, 10, 15, 6, 12, 16, 2, 3];
    skill_num = 4;
    skills = assignSkills();
    proficiencies = ["Light armor","Simple weapons","Hand crossbows",
                      "Longswords","Rapier","Shortswords"];
    abilities = ["Expertise", "Sneak Attack", "Thieves' Cant"];
    background = "Charlatan";
    wealth = getGold(4,10);
    this.print_it();
  }
}

class Sorcerer extends Character {
  Map stat_weights = {
    "Str": 1,
    "Dex": 2,
    "Con": 5,
    "Int": 4,
    "Wis": 3,
    "Cha": 6
  };

  Sorcerer(){
    class_name = "Sorcerer";
    assignStats();
    statMod(race);
    hit_die = 6;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Con","Cha"];
    equipment = [getRand([["Light crossbow, Bolts * 20"],"Simple weapon"]),
                  getRand(["Component pouch","Arcane focus"]),
                  getRand(["Dungeoneer's Pack","Explorer's pack"]),"Dagger * 2"];
    potential_skills = [4, 14, 10, 15, 17, 8];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Daggers","Darts","Slings",
                     "Quarterstaffs","Light crossbows"];
    abilities = ["Cantrips * 3", "Spells * 2",
                 "Sorcerous Origin: " + getRand(["Draconic Bloodline","Wild Magic"])];
    background = "Hermit";
    wealth = getGold(3,10);
    this.print_it();
  }
}

class Warlock extends Character {
  Map stat_weights = {
    "Str": 1,
    "Dex": 2,
    "Con": 5,
    "Int": 4,
    "Wis": 3,
    "Cha": 6
  };

  Warlock(){
    class_name = "Warlock";
    assignStats();
    statMod(race);
    hit_die = 6;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Wis","Cha"];
    equipment = [getRand([["Light crossbow","Bolts * 20"],"Simple weapon"]),
                  getRand(["Component pouch","Arcane focus"]),
                  getRand(["Scholar's pack","Dungeoneer's pack"]),
                  "Leather armor","Simple weapon","Dagger * 2"];
    potential_skills = [4, 14, 5, 15, 6, 7, 8];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Light armor", "Simple weapons"];
    abilities = ["Cantrips * 2", "Spells * 2",
                  "Otherworldly Patron", "Pact Magic"];
    background = "Charlatan";
    wealth = getGold(4,10);
    this.print_it();
  }
}

class Wizard extends Character {
  Map stat_weights = {
    "Str": 1,
    "Dex": 2,
    "Con": 4,
    "Int": 6,
    "Wis": 5,
    "Cha": 3
  };

  Wizard(){
    class_name = "Wizard";
    assignStats();
    statMod(race);
    hit_die = 6;
    hit_points = hit_die + ((stats["Con"]-10)/2).floor();
    saves = ["Int","Wis"];
    equipment = [getRand(["Quarterstaff","Dagger"]),
                  getRand(["Component pouch","Arcane focus"]),
                  getRand(["Scholar's pack","Explorer's pack"]),
                  "Spellbook"];
    potential_skills = [4, 5, 10, 6, 11, 8];
    skill_num = 2;
    skills = assignSkills();
    proficiencies = ["Daggers","Darts","Slings",
                     "Quarterstaffs","Light crossbows"];
    abilities = ["Cantrips * 3", "Spells * 6"];
    background = "Sage";
    wealth = getGold(4,10);
    this.print_it();
  }
}

// Error abstraction
void argError(String err_text) {
  throw new ArgumentError("Argument error: $err_text");
}

// Reads arguments passed to the script and executes them
// Each flag has a closure to be executed ("exec") and
// a "skip" variable that indicates whether the next argument
// should be a modifier for the current flag
// For example: the "-m" flag does not take a modifier, so "skip" is false
// the "-n" flag needs to be followed by a name, so "skip" is true
void parseArgs(List<String> args) {
  void am_lb() { lb = "%r"; }
  void am_nm(String nm) { sel_name = nm; }
  void am_cls(String cls) { sel_class = clsmap[cls.toLowerCase()]; }
  void am_rc(String rc) { sel_race = rc[0].toUpperCase() + rc.substring(1); }
  Map arg_map = {
    "-m": {
      "exec": () { am_lb(); },
      "skip": false
    },
    "--mush": {
      "exec": () { am_lb(); },
      "skip": false
    },
    "-n": {
      "exec": (nm) { am_nm(nm); },
      "skip": true
    },
    "--name": {
      "exec": (nm) { am_nm(nm); },
      "skip": true
    },
    "-c": {
      "exec": (cls) { am_cls(cls); },
      "skip": true
    },
    "--class": {
      "exec": (cls) { am_cls(cls); },
      "skip": true
    },
    "-r": {
      "exec": (rc) { am_rc(rc); },
      "skip": true
    },
    "--race": {
      "exec": (rc) { am_rc(rc); },
      "skip": true
    }
  };
  for (var i = 0; i < args.length; i++) {
    var arg = args[i];
    if (arg_map.keys.contains(arg)) {
      var arg_inst = arg_map[arg];
      var arg_exec = arg_inst['exec'];
      var arg_skip = arg_inst['skip'];
      var arg_next = null;
      if (arg_skip == true) {
        try {
          arg_next = args[i+1];
        } on Exception catch (e) {
          print(e);
          argError("$arg requires an additional parameter but none was supplied");
        }
        if (arg_next[0] == "-") {
          argError("$arg requires an additional parameter but another flag followed");
        }
        arg_exec(args[i+1]);
        i++;
      } else {
        arg_exec();
      }
    } else {
      argError("$arg isn't recognized");
    }
  }
}

void main(List<String> args) {
  parseArgs(args);

  var cls_choice = null;
  if (sel_class == null) {
    cls_choice = reflectClass(getRand(CLASSES));
  } else {
    cls_choice = reflectClass(sel_class);
  }

  var character = cls_choice.newInstance(new Symbol(''),[]).reflectee;
  // characters print themselves by default, so no need to do anything else.
}
