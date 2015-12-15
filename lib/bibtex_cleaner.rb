require "bundler/setup"
require "levenshtein"
require "bibtex"
require "readline"

module BibtexCleaner
end

class BibTeX::Entry
  def multiple_choice(f, bibtexen)
    choices = bibtexen.map { |b| [(b.send(f) if b.respond_to?(f)), b.title, b.author] }
    choices = choices.reject { |c| "#{c.first}".empty? }.uniq { |c| "#{c.first}" }

    return choices.first.first if choices.size == 1
    return "" if choices.size == 0

    puts "Choose #{f}! (or enter your own, 0 is the original or suggested entry)"
    choices.each_with_index do |choice, idx|
      puts "[#{idx}] \"#{choice.first}\"\n\t\t\t\t(#{choice[1]}, #{choice[2]})"
    end
    answer = Readline.readline.strip
    result = if answer =~ /\d+/
               choices[answer.to_i].first
             elsif answer.empty?
               choices[0].first
             else
               answer
             end
    puts result
    result
  end

  def merge_interactively(other_entries, required_fields)
    new_entry = {
      bibtex_type: multiple_choice(:type, [self] + other_entries),
      key: self.key
    }
    fields = required_fields[new_entry[:bibtex_type]]
    if fields.nil?
      self.key = "XXX_NOT_CLEANED_#{self.key}"
      fields = []
    end

    unless fields.empty?
      other_entries = other_entries.select do |b|
        b.type == new_entry[:bibtex_type]
      end
      new_entry[:title] = multiple_choice(:title, [self] + other_entries)
      other_entries = other_entries.select do |b|
        Levenshtein.normalized_distance(b.title.to_s, new_entry[:title].to_s) < 0.5
      end
      fields.each do |f|
        new_entry[f] = multiple_choice(f, [self] + other_entries)
      end
      BibTeX::Entry.new(new_entry)
    else
      self
    end
  end
end

class BibTeX::Bibliography
  def unify_interactively(field)
    elements = entries.values
    todo = elements.clone

    elements.each do |prime|
      next unless todo.include?(prime)
      if prime.respond_to?(field) && prime.send(field)
        primevalue = prime.send(field).to_s
        todo.delete(prime)

        es = todo.select do |e|
          e.respond_to?(field) && Levenshtein.normalized_distance(
            e.send(field).to_s.downcase.gsub(/[^A-Za-z]/, "").split.sort.join(" "),
            primevalue.downcase.gsub(/[^A-Za-z]/, "").split.sort.join(" ")) < 0.4
        end

        if (es + [prime]).uniq { |e| e.send(field).to_s }.size > 1
          puts "#{field}: #{primevalue}"
          puts "These seem similar -- write (comma separated) which entries do belong in this list (or press return to skip all)"
          es.each_with_index do |e, i|
            puts "[#{i}] #{e.send(field)}"
          end
          answer = Readline.readline.strip
          unless answer.empty?
            rejects = answer.strip.split(",").map(&:strip).map(&:to_i)
            es = es.each_with_index.select do |(e, idx)|
              rejects.include? idx
            end.map(&:first)
          else
            es = []
          end
        end

        puts "Now, enter the desired common writing for this, press return to keep all values as they are, enter '.' to apply the prime writing"
        puts "#{primevalue}"
        es.each_with_index do |e, i|
          puts "#{e.send(field)}"
        end
        answer = Readline.readline("", true).strip
        unless answer.empty?
          if answer == "."
            answer = primevalue
          else
            prime.send("#{field}=", answer)
          end
          es.each do |e|
            e.send("#{field}=", answer)
            todo.delete(e)
          end
        end
        puts "\n\n"
        yield if block_given?
      end
    end
  end
end
