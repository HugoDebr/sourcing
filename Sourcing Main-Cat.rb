require "open-uri"
require "nokogiri"
require "json"

url = "https://www.europages.fr/bs"

html_file = File.open("result.html").read
html_doc = Nokogiri::HTML.parse(html_file)

def extract_bs_links(html_doc)
  links = []
  html_doc.css('a').each do |link|
    href = link['href']
    if href && href.start_with?('/bs/')
      text = link.text.strip
      links << { text: text, href: href }
    end
  end
  p links
end

bs_links = extract_bs_links(html_doc)

def save_to_json(data, filename)
  File.open(filename, "w") do |file|
    file.write(JSON.pretty_generate(data))
  end
end

save_to_json(bs_links, "bs_links.json")

puts "Links starting with /bs/ saved to bs_links.json"




#/bs/energie-et-matieres-premieres
