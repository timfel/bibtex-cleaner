require "mechanize"

module BibtexCleaner
  module ACM
    def self.bibtex_for(querystr, limit = 4)
      agent = Mechanize.new
      page = agent.get("http://dl.acm.org/results.cfm", query: querystr, srt: "_score")

      page.links.
        select { |l| l.href =~ /citation.cfm\?id/ }[0...limit].
        map do |l|
        BibTeX.parse(
          agent.get(l.href.sub("citation.cfm", "exportformats.cfm") + "&expformat=bibtex").
          links.detect { |l| l.to_s =~ /download/i }.click.content
        ).entries.values
      end.flatten
    end
  end
end
