require "mechanize"

module BibtexCleaner
  module Springer
    def self.bibtex_for(querystr, limit = 4)
      agent = Mechanize.new
      page = agent.get("http://link.springer.com/search", query: querystr)

      page.links.
        select { |l| l.href =~ /link.springer.com\/(chapter|article)\/.+\/.+/ }[0...limit].
        map do |l|
        BibTeX.parse(
          agent.get(l.href.sub("link.springer.com/", "link.springer.com/export-citation") + ".bib").content
        ).entries.values
      end.flatten
    end
  end
end
