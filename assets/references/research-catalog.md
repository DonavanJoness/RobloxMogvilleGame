# Candidate research backlog

**Online verification is blocked.** The configured proxy denied the tested Wikipedia, Wikimedia Commons, Models.com and Know Your Meme connections with `403 Forbidden` on 2026-10-28. No source page, photograph, photographer attribution, license or age evidence was retrieved. This is a proposed index of 25 public-figure/model candidates plus two unresolved requested aliases, not a completed online research catalog.

The JSON is the structured record. Every candidate remains `NeedsApproval`; no portrait files or guessed Commons filenames were added. `sourceURL` values are proposed lookup targets and are explicitly marked `ProposedUnfetched`. Public-model candidates are not being described as looksmaxxing creators or as endorsing the game.

## Proposed candidates

| Candidate | Proposed lookup target (unfetched) | Suggested rarity / income / attack |
| --- | --- | --- |
| Clavicular | [Clavicular](https://knowyourmeme.com/memes/people/clavicular) | Mythic / 65 / 48 |
| Francisco Lachowski | [Francisco Lachowski](https://en.wikipedia.org/wiki/Francisco_Lachowski) | Divine / 165 / 66 |
| Henry Cavill | [Henry Cavill](https://en.wikipedia.org/wiki/Henry_Cavill) | Divine / 165 / 66 |
| Ernest Khalimov | [Ernest Khalimov](https://en.wikipedia.org/wiki/Ernest_Khalimov) | Ascended / 500 / 110 |
| Jordan Barrett | [Jordan Barrett](https://en.wikipedia.org/wiki/Jordan_Barrett) | Divine / 165 / 66 |
| David Gandy | [David Gandy](https://en.wikipedia.org/wiki/David_Gandy) | Uncommon / 7 / 20 |
| Sean O’Pry | [Sean O’Pry](https://en.wikipedia.org/wiki/Sean_O'Pry) | Rare / 20 / 32 |
| Lucky Blue Smith | [Lucky Blue Smith](https://en.wikipedia.org/wiki/Lucky_Blue_Smith) | Mythic / 65 / 48 |
| Jon Kortajarena | [Jon Kortajarena](https://en.wikipedia.org/wiki/Jon_Kortajarena) | Common / 2 / 12 |
| Marlon Teixeira | [Marlon Teixeira](https://en.wikipedia.org/wiki/Marlon_Teixeira) | Uncommon / 7 / 20 |
| Tyson Beckford | [Tyson Beckford](https://en.wikipedia.org/wiki/Tyson_Beckford) | Rare / 20 / 32 |
| Marcus Schenkenberg | [Marcus Schenkenberg](https://en.wikipedia.org/wiki/Marcus_Schenkenberg) | Mythic / 65 / 48 |
| David Agbodji | [David Agbodji](https://en.wikipedia.org/wiki/David_Agbodji) | Common / 2 / 12 |
| Alton Mason | [Alton Mason](https://en.wikipedia.org/wiki/Alton_Mason) | Uncommon / 7 / 20 |
| Pietro Boselli | [Pietro Boselli](https://en.wikipedia.org/wiki/Pietro_Boselli) | Rare / 20 / 32 |
| Alex Lundqvist | [Alex Lundqvist](https://en.wikipedia.org/wiki/Alex_Lundqvist) | Mythic / 65 / 48 |
| Noah Mills | [Noah Mills](https://en.wikipedia.org/wiki/Noah_Mills) | Common / 2 / 12 |
| Mathias Lauridsen | [Mathias Lauridsen](https://en.wikipedia.org/wiki/Mathias_Lauridsen) | Uncommon / 7 / 20 |
| Garrett Neff | [Garrett Neff](https://en.wikipedia.org/wiki/Garrett_Neff) | Rare / 20 / 32 |
| Kit Butler | [Kit Butler](https://en.wikipedia.org/wiki/Kit_Butler) | Mythic / 65 / 48 |
| Simon Nessman | [Simon Nessman](https://en.wikipedia.org/wiki/Simon_Nessman) | Common / 2 / 12 |
| Andrés Velencoso | [Andrés Velencoso](https://en.wikipedia.org/wiki/Andr%C3%A9s_Velencoso) | Uncommon / 7 / 20 |
| Baptiste Giabiconi | [Baptiste Giabiconi](https://en.wikipedia.org/wiki/Baptiste_Giabiconi) | Rare / 20 / 32 |
| Clément Chabernaud | [Clément Chabernaud](https://en.wikipedia.org/wiki/Cl%C3%A9ment_Chabernaud) | Mythic / 65 / 48 |
| River Viiperi | [River Viiperi](https://en.wikipedia.org/wiki/River_Viiperi) | Common / 2 / 12 |
| Kaysh | Missing; reference needed | Unresolved; no gameplay mapping |
| Post-Surgery Hexum | Missing; reference needed | Unresolved; no gameplay mapping |

## Explicit unresolved labels

- **Kaysh:** no unambiguous person, public profile, age or reference image has been established. A specific source link is required.
- **Post-Surgery Hexum:** the label is unresolved. It must not be mapped to Jon-Erik Hexum or used to claim a medical history. No surgery association has been verified.

## Complete each record before approval

1. Confirm the person and alias from an authoritative public source; record an exact URL, retrieved evidence and adult status. Confirm the selected photograph depicts the person as an adult.
2. Select a specific image and record its source page, photographer, exact license URL and any attribution or share-alike obligations. Do not infer commercial permission from public availability.
3. Record separate applicable likeness permission for recognizable-person gameplay use. A Wikimedia image license does not by itself supply that permission.
4. Only after both rights records are approved, add a local portrait file, preserve attribution and configure the production asset pipeline. Until then, retain the existing fictional game roster.

Suggested gameplay values are fictional balancing proposals. They do not represent beauty ratings or claims about real-world ability. The five mutations are fictional visual variants, not claims about a person’s body or medical history.

## Reproduce source collection

After the research hosts are enabled in environment settings, run `python3 tools/research_candidates.py --candidate francisco_lachowski` from the repository. The helper uses official MediaWiki JSON APIs, preserves proxy/TLS settings, checks robots permissions, spaces requests at least one second apart, and writes source evidence without downloading portraits or automatically approving any record. It exits unsuccessfully on denied or missing evidence. Review evidence manually before changing approval states.

See `source-access.json` for observed denials and `research-catalog.json` for structured candidate and rights fields.
