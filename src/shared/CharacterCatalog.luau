--!strict
-- Original fictional identities and forms. Character ID remains the save key;
-- identityId groups forms without turning a form or mutation into a new person.
-- Existing entries are metadata only: Config preserves all original gameplay stats.
local CharacterCatalog = {}

CharacterCatalog.Forms = {
	Young = { name = "Young", order = 1, description = "An early-career version of the same fictional identity." },
	Classic = { name = "Classic", order = 2, description = "The signature version of this fictional identity." },
	Prime = { name = "Prime", order = 3, description = "A seasoned version with its own balanced gameplay stats." },
	Ascended = { name = "Ascended", order = 4, description = "A cosmic-styled version; mutation remains an independent roll." },
}

CharacterCatalog.Identities = {
	rookie = { name = "Rookie Star", description = "An optimistic square-haired newcomer with a lightning-shaped lapel." },
	fade = { name = "Fresh Fade", description = "A mint-jacketed neighborhood stylist with a geometric flat-top." },
	pose = { name = "Pose Apprentice", description = "A pink-clad stage student who strikes a star-shaped pose." },
	jawline = { name = "Jawline Junior", description = "A friendly green-scarfed adventurer with an exaggerated blocky chin." },
	gym = { name = "Gym Bro", description = "An orange-tracksuited strength enthusiast with oversized foam wristbands." },
	runway = { name = "Runway Star", description = "A blue-cloaked showstopper wearing an asymmetric star brooch." },
	champion = { name = "Chiseled Champion", description = "A cyan-armored guardian with a sculpted geometric helmet." },
	gold = { name = "Golden Chad", description = "A fictional gold-suited host with a sunburst tie and a bright grin." },
	royalty = { name = "Mog Royalty", description = "A violet-caped royal whose crown is made of floating diamond shapes." },
	icon = { name = "Divine Icon", description = "A cream-and-gold celestial performer surrounded by a stylized ring halo." },
	stylist = { name = "Celestial Stylist", description = "An icy-blue cosmic tailor with orbiting ribbon shapes." },
	apex = { name = "Apex Mogger", description = "An original pink cosmic champion with a prism crest and starry shoulder pads." },
}

CharacterCatalog.Existing = {
	young_rookie = { identityId = "rookie", form = "Young", description = "Rookie Star's first day in Mogville: a violet hoodie, tiny lightning pin and boundless confidence.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	fresh_fade = { identityId = "fade", form = "Classic", description = "Fresh Fade's mint bomber jacket and crisp geometric flat-top are ready for the neighborhood spotlight.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	pose_apprentice = { identityId = "pose", form = "Young", description = "A pink-clad performer practicing a big stage pose with a little star badge.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	jawline_junior = { identityId = "jawline", form = "Young", description = "A cheerful blocky adventurer wearing a green scarf and a proudly oversized chin guard.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	gym_bro = { identityId = "gym", form = "Classic", description = "Gym Bro's signature orange tracksuit, square headband and giant foam wristbands.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	runway_rookie = { identityId = "runway", form = "Young", description = "Runway Star's debut blue cape and oversized star brooch, with a playful blocky silhouette.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	chiseled_champion = { identityId = "champion", form = "Prime", description = "A cyan guardian in angular armor and a geometric helmet, standing ready to protect Starter Square.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	golden_chad = { identityId = "gold", form = "Classic", description = "A beaming fictional host in a gold suit, sunburst tie and chunky square sunglasses.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	mog_king = { identityId = "royalty", form = "Classic", description = "Mog Royalty's violet cape and floating diamond crown bring theatrical flair to the square.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	divine_icon = { identityId = "icon", form = "Prime", description = "A cream-and-gold celestial showstopper with a ring halo and a sunlit geometric robe.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	celestial_stylist = { identityId = "stylist", form = "Prime", description = "An icy-blue cosmic tailor arranging bright orbiting ribbons into a spectacular silhouette.", portraitAssetId = 0, enabled = true, mutationEligible = true },
	apex_mogger = { identityId = "apex", form = "Ascended", description = "A pink prism-crested champion with starry shoulder pads and a wholly fictional cosmic aura.", portraitAssetId = 0, enabled = true, mutationEligible = true },
}

-- Every entry below is its own rollable form, not an evolution promise or a
-- mutation. Numerical rarity odds remain centralized in Config.Rarities.
CharacterCatalog.Added = {
	rookie_classic = {
		name = "Rookie Star", identityId = "rookie", form = "Classic", rarity = "Uncommon",
		income = 8, attack = 21, defense = 9, health = 110, speed = 16,
		ability = "Strong Jaw", color = "90A4FF", weight = 1,
		description = "Rookie Star trades the hoodie for a violet varsity jacket, keeping the familiar lightning pin.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	rookie_prime = {
		name = "Rookie Prime", identityId = "rookie", form = "Prime", rarity = "Rare",
		income = 22, attack = 34, defense = 14, health = 155, speed = 23,
		ability = "Strong Jaw", color = "8599FF", weight = 1,
		description = "The same square-haired optimist now wears a tailored violet coat and a silver lightning crest.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	rookie_ascended = {
		name = "Rookie Ascended", identityId = "rookie", form = "Ascended", rarity = "Ascended",
		income = 460, attack = 105, defense = 46, health = 395, speed = 43,
		ability = "Final Form", color = "BAA5FF", weight = 1,
		description = "Rookie Star's familiar lightning crest becomes a constellation above a violet cosmic coat.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	runway_classic = {
		name = "Runway Star", identityId = "runway", form = "Classic", rarity = "Rare",
		income = 21, attack = 31, defense = 15, health = 150, speed = 28,
		ability = "Spotlight", color = "76C8FF", weight = 1,
		description = "Runway Star flourishes a long blue cape, asymmetric star brooch and tall geometric collar.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	runway_prime = {
		name = "Runway Prime", identityId = "runway", form = "Prime", rarity = "Mythic",
		income = 72, attack = 50, defense = 24, health = 210, speed = 33,
		ability = "Spotlight", color = "79A5FF", weight = 1,
		description = "A seasoned Runway Star wears a cobalt coat with a silver star trail stitched across the cape.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	runway_ascended = {
		name = "Runway Ascended", identityId = "runway", form = "Ascended", rarity = "Ascended",
		income = 490, attack = 106, defense = 47, health = 405, speed = 48,
		ability = "Final Form", color = "80DEFF", weight = 1,
		description = "Runway Star's blue cape becomes a flowing starfield while the signature brooch glows like a small sun.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	king_young = {
		name = "Little Mog Prince", identityId = "royalty", form = "Young", rarity = "Uncommon",
		income = 8, attack = 22, defense = 10, health = 110, speed = 16,
		ability = "Intimidate", color = "B89BFF", weight = 1,
		description = "Mog Royalty begins with an oversized violet scarf and a single floating diamond above a paper crown.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	king_prime = {
		name = "Mog Sovereign", identityId = "royalty", form = "Prime", rarity = "Divine",
		income = 185, attack = 79, defense = 33, health = 295, speed = 33,
		ability = "Intimidate", color = "C3A0FF", weight = 1,
		description = "The violet-caped sovereign wears a broad diamond crown and a geometric silver mantle.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	king_ascended = {
		name = "Mog Monarch Ascended", identityId = "royalty", form = "Ascended", rarity = "Ascended",
		income = 520, attack = 114, defense = 50, health = 425, speed = 40,
		ability = "Final Form", color = "D4A5FF", weight = 1,
		description = "Mog Royalty's crown becomes a tiny orbit of violet diamonds above a star-lined ceremonial cape.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	gym_young = {
		name = "Tiny Gym Bro", identityId = "gym", form = "Young", rarity = "Common",
		income = 2.5, attack = 13, defense = 4, health = 72, speed = 11,
		ability = "Strong Jaw", color = "FFC292", weight = 1,
		description = "An eager young Gym Bro in an orange tee, with comically large foam wristbands and a square headband.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	gym_prime = {
		name = "Gym Bro Prime", identityId = "gym", form = "Prime", rarity = "Rare",
		income = 25, attack = 37, defense = 16, health = 165, speed = 19,
		ability = "Intimidate", color = "FFA668", weight = 1,
		description = "A veteran Gym Bro sports an orange-and-black tracksuit, angular shoulder pads and the same cheerful headband.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
	gym_ascended = {
		name = "Gym Bro Ascended", identityId = "gym", form = "Ascended", rarity = "Divine",
		income = 190, attack = 82, defense = 38, health = 320, speed = 25,
		ability = "Final Form", color = "FFBE7D", weight = 1,
		description = "Gym Bro's orange tracksuit glows with solar seams; oversized foam wristbands become two tiny ringed planets.",
		portraitAssetId = 0, enabled = true, mutationEligible = true,
	},
}

return CharacterCatalog
