require "mechanize"
require "dblp"

module BibtexCleaner
  module DBLP
    def self.bibtex_for(querystr, limit = 4)
      agent = Mechanize.new
      page = agent.get("http://dblp.uni-trier.de/search", q: querystr)

      page.links.
        select { |l| l.href =~ /rec\/bibtex\/(.+)/; $1 }.compact[0...limit].
        map do |dblpkey|
        BibTeX.parse(
          agent.get("http://dblp.uni-trier.de/rec/bib2/#{dblpkey}.bib").content
        ).entries.values
      end.flatten
    end
  end
end
