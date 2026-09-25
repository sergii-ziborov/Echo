import Foundation

/// Where each campaign map sits on the Fold Road and what the Signal finds
/// there. Every line matches the map's hazards, so the story explains the
/// rules instead of decorating them.
enum LevelLore {
    struct Entry: Equatable, Sendable {
        let place: String
        let log: String
    }

    static func entry(for number: Int) -> Entry? {
        entries.indices.contains(number - 1) ? entries[number - 1] : nil
    }

    static let entries: [Entry] = [
        // THE LIGHTHOUSE
        Entry(place: "Lamp Deck", log: "The Signal wakes on the lamp deck. Gather the loose seconds lying here, and the first fold will open."),
        Entry(place: "Service Ring", log: "A ring corridor wraps the dead lamp. When the power failed, its sparks slid to the far ends."),
        Entry(place: "Coolant Crossing", log: "Two maintenance halls cross here, and spilled coolant has thickened time into a mire."),
        Entry(place: "Mirror Hall", log: "The lamp's mirrors still hold afterimages. A calm tear stops hostile time while you stand inside it."),
        Entry(place: "The Orrery", log: "The Keepers' orrery still turns, and its sparks ride the brass orbits without waiting for you."),
        Entry(place: "Flooded Well", log: "Time pools in the observation well like standing water. Wade the edges; the middle holds you."),
        Entry(place: "Keeper's Vault", log: "The Keepers left a shield in their vault. Past its door the first fold opens onto the Road."),
        // DRIFT GARDENS
        Entry(place: "Twin Domes", log: "Two greenhouse domes share one airlock, and it opens on its own clock, not yours."),
        Entry(place: "Planting Terraces", log: "Terraces zigzag past a stuck lock. Every switchback you climb is a wall your echo will walk."),
        Entry(place: "Trellis Ward", log: "Vine trellises cut the dome into cells. Leave gaps; you will pass through each one twice."),
        Entry(place: "Seed Vault", log: "The seed vault still blooms with stored power. Take every bonus — you will need them all."),
        Entry(place: "Hydro Core", log: "The garden's hydro core floods its own hall. Five echoes crowd the pumps; spend what you carry."),
        Entry(place: "Root Maze", log: "Roots split the tunnels into branches. The one you skip is the one you walk later."),
        Entry(place: "Outer Hatches", log: "Offset hatches line the ring's edge. Turn back and your path is taken; the fold waits past the last one."),
        // TESSERA SHELF
        Entry(place: "Ice Harbor", log: "An old ice harbor curls into a U on Tessera's shelf. You will have to leave it twice."),
        Entry(place: "Frost Shaft", log: "A shaft drops through the shelf with gaps on opposite walls. Remember which side you used."),
        Entry(place: "Pressure Ridge", log: "The ice has buckled into steps. What you climb becomes a wall on the way down."),
        Entry(place: "Meltwater Pockets", log: "Four meltwater pockets open off one chamber, and your echo remembers every one."),
        Entry(place: "The Crevasse", log: "Thin lanes run between the ice sheets. Your echoes are wider than they look."),
        Entry(place: "Shelf Storm", log: "A time storm throws the first loose rock across the shelf. Everything moves; find where to be still."),
        Entry(place: "Breakaway", log: "Whole slabs break off Tessera and drift toward the belt. So does the fold."),
        // HOLLOW BELT
        Entry(place: "Inner Belt", log: "The first of Cinder's remains, glowing magma and meteoric iron. A patrolling rock already owns your lane."),
        Entry(place: "Comet Lane", log: "Captured rock circles the fold like a small moon. It is not scenery."),
        Entry(place: "Crossfire", log: "Two patrols cross one gap, and a collapsing tear waits beside them."),
        Entry(place: "Shrapnel Field", log: "Cinder's crust is ground to shrapnel here. Small rocks, bad timing."),
        Entry(place: "Emberwake", log: "A slow field and a drifting crystal share one rhythm in Cinder's warm wake."),
        Entry(place: "Frostlane", log: "Cold drifts in from the belt's far side. Freeze the rocks, then spend the quiet."),
        Entry(place: "Magnetar Pass", log: "A magnetar shakes the belt loose as the Road leaves it. Pull the sparks in; dodge what it throws."),
        // PROVING GROUNDS
        Entry(place: "Sluice Test", log: "The first test chamber runs two patrols on the same delay. Learn the beat before the beams wake."),
        Entry(place: "Gauntlet", log: "Echoes, rock, mire and two tears in one hall. The Keepers called it a warm-up."),
        Entry(place: "Prism Hall", log: "The first sentinel beams. The warning line is safe; the bright line is not."),
        Entry(place: "Relay Locks", log: "Two locks keep two clocks between the beams. Cross on one, return on the other."),
        Entry(place: "Impact Chamber", log: "Rock is hurled at the walls to test the locks. Read the lanes before the impacts change them."),
        Entry(place: "Cold Circuit", log: "A frozen test loop. Freeze holds every beam and every ticking crystal."),
        Entry(place: "Phase Array", log: "Three beams, three beats, one route: the Keepers' last exam before Ashcrown."),
        // ASHCROWN CORONA
        Entry(place: "Firing Core", log: "Four sectors ring a core that fires on the star's pulse. Clear them, then cross it."),
        Entry(place: "The Corona", log: "Ashcrown's flares glow before they fire. Read the light."),
        Entry(place: "Twinfire", log: "Two flares, two safe lanes, never safe at the same time."),
        Entry(place: "Redshift", log: "Light stretches as the star falls in on itself, and the arena speeds up behind you."),
        Entry(place: "Lensing Core", log: "A shard of the star too heavy to move holds three smaller ones in orbit."),
        Entry(place: "Pulse Crown", log: "The flares fire in a crown. Break the rhythm at its center."),
        Entry(place: "Zero Hour", log: "Every law of the horizon at once — then Ashcrown folds, and tears the Road open."),
        // THE RIFTLANDS
        Entry(place: "First Tear", log: "The first door opens somewhere else. Step in, and come out across the arena."),
        Entry(place: "Foldline", log: "Cross once, and return on a different axis."),
        Entry(place: "Split Realm", log: "One arena, two routes that cannot both be true."),
        Entry(place: "Backstep", log: "This tear throws your timeline backward. Your echo remembers where."),
        Entry(place: "False Door", log: "The fold moves. The heavy core beside it does not."),
        Entry(place: "Broken Axis", log: "When the world folds, your steering folds with it."),
        Entry(place: "Rift Heart", log: "The tear at the heart of the Riftlands. Use the breach before it uses you."),
        // THE UNDERTOW
        Entry(place: "Dark Tide", log: "The first well of the Undertow. It pulls long before it kills."),
        Entry(place: "Orbit Fall", log: "Orbit wide, then cut across the tide."),
        Entry(place: "Gravity Choir", log: "Three moving bodies sing to a single well."),
        Entry(place: "Bent Route", log: "This close to the dark, your straightest route will bend."),
        Entry(place: "Well Spring", log: "Sparks pool at the edge of the pull, where the dark almost lets go."),
        Entry(place: "Tidal Lock", log: "The well and the beam keep one clock."),
        Entry(place: "Dark Star", log: "Nothing leaves without a planned loop. Past this star the light starts to split."),
        // GLASS NEBULA
        Entry(place: "Doppelglass", log: "The nebula shows a second copy of the arena. The reflection is mechanically real."),
        Entry(place: "Inversion", log: "Pass through this tear and left becomes wrong for four seconds."),
        Entry(place: "False North", log: "The compass lies inside the glass. Trust the crystal."),
        Entry(place: "Phase Garden", log: "Phase through the route the map denies."),
        Entry(place: "Echo Mask", log: "Three reflections circle a single fixed danger."),
        Entry(place: "Glass Labyrinth", log: "The walls are honest. The breach is not."),
        Entry(place: "Dream Collapse", log: "The mirrored world is closing. Wake up — or fall into the dream beneath it."),
        // CANDY TIMELINE
        Entry(place: "Sugar Static", log: "The first taste of the dream: a sweeter reality that runs faster."),
        Entry(place: "Gumdrop Orbit", log: "Orbit the gumdrops, and stay off your old line."),
        Entry(place: "Frosting Rail", log: "The rails are made of frosting. The light on them is still lethal."),
        Entry(place: "Candy Comet", log: "The prettiest path has moving teeth."),
        Entry(place: "Crystal Syrup", log: "One candy moon, three restless satellites."),
        Entry(place: "Sweet Paradox", log: "Build resonance while the rules are soft."),
        Entry(place: "Candy Timeline", log: "Enter hungry, and leave before the dream hardens. The last fold points home."),
        // LAST DAWN
        Entry(place: "Lamp Deck, Last Dawn", log: "The deck where you woke, under the last light of time. Everything learned returns at once."),
        Entry(place: "All Pasts", log: "Every route you ever drew waits in the Lighthouse's halls."),
        Entry(place: "Infinite Scar", log: "Scars, wells and tears share the arena where the break began."),
        Entry(place: "Final Mirror", log: "Cross the fold without trusting your hand."),
        Entry(place: "Event Crown", log: "Take the center between four pulses."),
        Entry(place: "Forever Loop", log: "The loop ends only when you outrun it."),
        Entry(place: "The Lamp", log: "Seventy-seven stops answer with one last echo: the Signal the moment it was lit. The loop closes — and opens again."),
    ]
}
