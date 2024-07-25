require "open-uri"
require "nokogiri"
require "json"

# Charger le fichier JSON contenant les liens commençant par /bs/
def load_json(filename)
  file = File.read(filename)
  JSON.parse(file)
end

# Fonction pour obtenir le HTML d'une URL
def fetch_html(url)
  begin
    URI.open(url).read
  rescue OpenURI::HTTPError => e
    puts "Failed to retrieve #{url}: #{e.message}"
    return nil
  end
end

# Fonction pour extraire les liens commençant par /entreprises/
def extract_entreprises_links(html_doc)
  links = []
  html_doc.css('a').each do |link|
    href = link['href']
    if href && href.start_with?('/entreprises/')
      text = link.text.strip
      links << { text: text, href: href }
    end
  end
  links
end

# Fonction pour structurer les données en JSON
def structure_data(base_links, delay)
  data = []

  base_links.each do |base_link|
    full_url = "https://www.europages.fr#{base_link['href']}"
    puts "Processing: #{full_url}"
    html_file = fetch_html(full_url)

    if html_file
      html_doc = Nokogiri::HTML.parse(html_file)
      sub_links = extract_entreprises_links(html_doc)
      data << { base_link: base_link, sub_links: sub_links }
    end

    # Ajouter un délai pour éviter de surcharger le serveur
    sleep(0)
  end

  data
end

# Enregistrer les données structurées dans un fichier JSON
def save_to_json(data, filename)
  File.open(filename, "w") do |file|
    file.write(JSON.pretty_generate(data))
  end
end

# Charger les liens de catégories /bs/ depuis le fichier JSON
base_links = load_json("bs_links.json")

# Définir la durée du délai (en secondes)
delay = 0 # Vous pouvez ajuster cette valeur selon vos besoins

# Structurer les données avec un délai entre les requêtes
structured_data = structure_data(base_links, delay)

# Sauvegarder les données structurées dans un fichier JSON
save_to_json(structured_data, "structured_links.json")

puts "Structured data saved to structured_links.json"
