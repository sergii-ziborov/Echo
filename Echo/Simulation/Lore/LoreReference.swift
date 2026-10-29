import Foundation

/// Sources inform the fiction without claiming that the Keepers' devices exist.
/// The interpretation belongs to ECHO; these are links, not borrowed quotations.
struct LoreReference: Identifiable, Sendable {
    let id: String
    let title: String
    let kind: Kind
    let url: URL

    enum Kind: String, Sendable { case primary, research, official, commentary }

    private init(_ id: String, _ title: String, _ kind: Kind, _ url: String) {
        self.id = id
        self.title = title
        self.kind = kind
        self.url = URL(string: url)!
    }

    static func references(for act: Act) -> [Self] {
        switch act {
        case .trace: [
            Self("epictetus", "Epictetus · Enchiridion §1", .primary, "https://classics.mit.edu/Epictetus/epicench.html"),
            Self("clock", "NIST · One-way time transfer", .official, "https://www.nist.gov/pml/time-and-frequency-division/time-services/one-way-gnss-time-transfer")]
        case .drift: [
            Self("aristotle", "Aristotle · Nicomachean Ethics II.1", .primary, "https://classics.mit.edu/Aristotle/nicomachaen.2.ii.html"),
            Self("feedback", "Åström & Murray · Feedback Systems", .research, "https://www.cds.caltech.edu/~murray/books/AM08/pdf/am08-intro_28Sep12.pdf")]
        case .fracture: [
            Self("heraclitus", "Heraclitus · Fragments", .primary, "https://sourcebooks.web.fordham.edu/ancient/heraklitos-fragments.asp"),
            Self("ice", "Rhoden et al. · Fracture mechanics", .research, "https://doi.org/10.1029/2020JE006710")]
        case .debris: [
            Self("marcus", "Marcus Aurelius · Meditations VII.54", .primary, "https://classics.mit.edu/Antoninus/meditations.7.seven.html"),
            Self("landauer", "Landauer · Irreversibility and heat", .research, "https://www.dna.caltech.edu/courses/cs191/paperscs191/landauer1961.pdf")]
        case .paradox: [
            Self("popper", "Popper · Conjectures and Refutations", .primary, "https://joelvelasco.net/teaching/hum9/popper-conjecturesrefutations.pdf"),
            Self("echo", "Shaffer et al. · Verification protocols", .research, "https://arxiv.org/abs/2003.04500")]
        case .singularity: [
            Self("socrates", "Plato · Apology 21b–23b", .primary, "https://classics.mit.edu/Plato/apology.html"),
            Self("light", "NASA · Looking into the past", .official, "https://science.nasa.gov/blogs/webb/2023/12/06/measuring-the-distances-to-galaxies-with-space-telescopes/"),
            Self("singularity", "NASA · Singularity", .official, "https://science.nasa.gov/universe/glossary/")]
        case .rift: [
            Self("kant", "Kant · Orientation, AA 8:134–135", .primary, "https://assets.cambridge.org/97811071/49595/excerpt/9781107149595_excerpt.pdf"),
            Self("einstein", "Einstein · Relativity (1905), §§1–3", .research, "https://physics.umd.edu/courses/Phys371/AnlageSpring17/Einstein_1905_relativity.pdf")]
        case .gravity: [
            Self("spinoza", "Spinoza · Ethics I, Axiom IV", .primary, "https://www.gutenberg.org/cache/epub/3800/pg3800-images.html"),
            Self("gravity", "NASA · Black holes and orbits", .official, "https://science.nasa.gov/universe/black-holes/")]
        case .mirage: [
            Self("plato", "Plato · Republic VII, 514a–517a", .primary, "https://classics.mit.edu/Plato/republic.8.vii.html"),
            Self("lensing", "NASA · Gravitational lenses", .official, "https://science.nasa.gov/mission/hubble/science/universe-uncovered/hubbles-gravitational-lenses/")]
        case .confection: [
            Self("epicurus", "Epicurus · Principal Doctrines 27", .primary, "https://classics.mit.edu/Epicurus/princdoc.html"),
            Self("pleasure", "Epicurus · Letter to Menoeceus", .primary, "https://classics.mit.edu/Epicurus/menoec.html"),
            Self("teaching", "Skinner · Teaching Machines (1958)", .research, "https://doi.org/10.1126/science.128.3330.969")]
        case .eternity: [
            Self("camus", "Stanford · Camus §3.4", .commentary, "https://plato.stanford.edu/entries/camus/"),
            Self("bennett", "Bennett · Logical reversibility (1973)", .research, "https://www.cs.princeton.edu/courses/archive/fall04/cos576/papers/bennett73.html")]
        }
    }
}
