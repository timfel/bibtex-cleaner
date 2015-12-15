require "cites"

module BibtexCleaner
  module DOI
    def self.bibtex_for(querystr, limit = 4)
      results = ::Cites.search(querystr)
      results["items"].select { |i| i["normalizedScore"] > 90 }.map do |i|
        BibTeX.
          parse(::Cites.doi2cit(i["doi"].sub(/^.+dx.doi.org\//, ""), "bibtex").first).
          entries.values
      end.flatten[0...limit]
    end
  end
end
