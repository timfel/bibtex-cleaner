#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "bibtex_cleaner"
require "bibtex_cleaner/acm"
require "bibtex_cleaner/dblp"
require "bibtex_cleaner/doi"
require "bibtex_cleaner/google"
require "bibtex_cleaner/ieee"
require "bibtex_cleaner/springer"

if ARGV.size < 3
  puts "Usage:\n\t#{File.basename(__FILE__)} -unify -clean input.bib output.bib"
  exit
end

unify = ARGV.delete("-unify")
clean = ARGV.delete("-clean")

b = BibTeX.open(ARGV[0])

if unify
  b.unify :publisher, /springer/i, "Springer"
  b.unify :publisher, /acm/i, "{ACM}"
  b.unify :publisher, /ieee/i, "{IEEE}"
  b.unify :publisher, /easychair/i, "{EasyChair}"
  b.unify :publisher, /mit/i, "{MIT} Press"
  b.unify :institution, /vpri|viewpoints/i, "Viewpoints Research Institute"
  b.unify :institution, /hpi|hasso.plattner.institut/i, "Hasso Plattner Institute"
  b.unify(:doi, /./) { |e| e.doi = e.doi.downcase }
  b.unify(:issn, /./) { |e| e.issn = e.issn.downcase }
  b.unify(:isbn, /./) { |e| e.isbn = e.isbn.downcase }
  b.unify(:pages, /\-/) { |e| e.pages = e.pages.gsub(/\-+/, "--") }

  b.unify(:journal, /\(?[A-Z][A-Z]+\)?/) do |e|
    unless e.journal =~ /{/
      e.journal = e.journal.gsub(/(\(?[A-Z][A-Z]+\)?)/, "{\\1}")
    end
  end
  b.unify(:booktitle, /\(?[A-Za-z]+\)/) do |e|
    unless e.booktitle =~ /{/
      e.booktitle = e.booktitle.gsub(/(\(?[A-Z][A-Z]+\)?)/, "{\\1}")
    end
  end

  b.unify_interactively(:journal) { b.save_to(ARGV[0]) }
  b.unify_interactively(:booktitle) { b.save_to(ARGV[0]) }
  b.unify_interactively(:publisher) { b.save_to(ARGV[0]) }
  b.unify_interactively(:organization) { b.save_to(ARGV[0]) }
  b.unify_interactively(:institution) { b.save_to(ARGV[0]) }

  b.save_to(ARGV[1])
end

if clean
  out = BibTeX::Bibliography.new
  inputthread = Thread.new {}

  b.entries.values.each do |e|
    querystr = "#{e.title} #{e.author} #{e.year} #{e.journal} #{e.booktitle}"
    nbibtexen = BibtexCleaner.constants.map { |c| BibtexCleaner.const_get(c) }.map do |m|
      begin
        m.bibtex_for(querystr) if m.respond_to? :bibtex_for
      rescue Exception; end
    end.flatten.compact

    inputthread.join
    bibtexen = nbibtexen
    inputthread = Thread.new do
      puts "\nCleaning #{e} ..."
      out << e.merge_interactively(
        bibtexen,
        inproceedings: [:author, :booktitle, :year, :month, :pages, :publisher, :doi],
        incollection: [:author, :booktitle, :year, :month, :pages, :publisher, :doi],
        phdthesis: [:author, :year, :month, :school],
        article: [:author, :journal, :number, :volume, :year, :month, :pages, :publisher, :doi],
        book: [:author, :year, :month, :isbn, :issn, :publisher, :doi, :edition],
        techreport: [:author, :year, :month, :number, :institution, :issn, :doi, :isbn],
        manual: [:author, :organization, :edition, :year, :month, :note],
        online: [:author, :day, :month, :year, :url, :note],
        misc: [:author, :month, :year, :howpublished, :note]
      )
      out.save_to(ARGV[1])
    end
  end

  out.save_to(ARGV[1])
end
