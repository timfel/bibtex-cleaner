require "gscholar"
require "mechanize"

module BibtexCleaner
  module Google
    def self.bibtex_for(querystr, limit = 4)
      agent = Mechanize.new
      page = agent.get("https://scholar.google.de/scholar", q: querystr)

      page.links.
        map { |l| l.href =~ /\?cites=(\d+)/; $1 }.compact[0..limit].
        map do |id|
        bibtex = GScholar::Paper.new(id).bibtex
        bibtex = bibtex.encode('ASCII', :invalid => :replace, :undef => :replace)
        BibTeX.parse(bibtex).entries.values
      end.flatten
    end
  end
end
