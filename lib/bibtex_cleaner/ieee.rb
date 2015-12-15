require "mechanize"

module BibtexCleaner
  module IEEE
    def self.bibtex_for(querystr, limit = 4)
      agent = Mechanize.new
      page = agent.get("http://ieeexplore.ieee.org/search/searchresult.jsp", queryText: querystr)

      page.links.
        map { |l| l.href =~ /arnumber=(\d+)/; $1 }.compact[0...limit].
        map do |id|
        bibtex = agent.post("http://ieeexplore.ieee.org/xpl/downloadCitations",
                            :recordIds => id,
                            "citations-format" => "citation-only",
                            "download-format" => "download-bibtex",
                            "x" => "74",
                            "y" => "7").content
        BibTeX.parse(bibtex).entries.values
      end.flatten
    end
  end
end
