require "open-uri"
require "nokogiri"
require "json"

# Charger le fichier JSON contenant les liens des sous-catégories
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

# Fonction pour extraire les noms et les liens des entreprises d'une page de résultats
def extract_company_links(html_doc)
  links = []
  html_doc.css('.ep-ecard-serp__epage-link').each do |link|
    href = link['href']
    if href
      # Sélection de l'élément parent pour extraire le nom de l'entreprise
      parent_element = link.ancestors('.ep-ecard').first
      company_name = parent_element.at_css('.ep-ecard__title.text-subtitle-1.font-weight-black.pa-3.pb-0.ma-0')&.text&.strip
      links << { text: company_name, href: href }
    end
  end
  links
end

# Fonction pour structurer les données en JSON pour une sous-catégorie
def structure_data_for_sub_category(base_link, sub_category_link, delay)
  data = {}

  category_name = base_link["text"]
  category_url = "https://www.europages.fr#{base_link['href']}"
  sub_category_name = sub_category_link["text"]
  sub_category_url = "https://www.europages.fr#{sub_category_link['href']}"

  data[category_name] = { url: category_url, sub_categories: {} }
  data[category_name][:sub_categories][sub_category_name] = { url: sub_category_url, companies: [] }

  page_number = 1
  loop do
    paginated_url = page_number == 1 ? sub_category_url : sub_category_url.gsub('/entreprises/', "/entreprises/pg-#{page_number}/")
    puts "Processing: #{paginated_url}"
    html_file = fetch_html(paginated_url)

    break unless html_file

    html_doc = Nokogiri::HTML.parse(html_file)
    sub_links = extract_company_links(html_doc)

    break if sub_links.empty?

    data[category_name][:sub_categories][sub_category_name][:companies].concat(sub_links)
    page_number += 1

    # Ajouter un délai pour éviter de surcharger le serveur
    sleep(delay)
  end

  data
end

# Fonction pour structurer les données en JSON pour toutes les catégories et sous-catégories
def structure_data_for_all_categories(all_links, delay)
  global_data = {}

  all_links.each do |category|
    base_link = category["base_link"]
    category_name = base_link["text"]
    category_url = "https://www.europages.fr#{base_link['href']}"
    global_data[category_name] = { url: category_url, sub_categories: {} }

    category["sub_links"].each do |sub_link|
      sub_category_name = sub_link["text"]
      sub_category_url = "https://www.europages.fr#{sub_link['href']}"
      global_data[category_name][:sub_categories][sub_category_name] = { url: sub_category_url, companies: [] }

      page_number = 1
      loop do
        paginated_url = page_number == 1 ? sub_category_url : sub_category_url.gsub('/entreprises/', "/entreprises/pg-#{page_number}/")
        puts "Processing: #{paginated_url}"
        html_file = fetch_html(paginated_url)

        break unless html_file

        html_doc = Nokogiri::HTML.parse(html_file)
        sub_links = extract_company_links(html_doc)

        break if sub_links.empty?

        global_data[category_name][:sub_categories][sub_category_name][:companies].concat(sub_links)
        page_number += 1

        # Ajouter un délai pour éviter de surcharger le serveur
        sleep(delay)
      end

      # Ajouter un délai pour éviter de surcharger le serveur
      sleep(delay)
    end
  end

  global_data
end

# Enregistrer les données structurées dans un fichier JSON
def save_to_json(data, filename)
  File.open(filename, "w") do |file|
    file.write(JSON.pretty_generate(data))
  end
end

# Charger les liens de sous-catégories depuis le fichier JSON
puts "Loading JSON file..."
all_links = load_json("Cat & Sub-Cat.json")
puts "Loaded JSON file successfully."

# Définir la durée du délai (en secondes)
delay = 0 # Vous pouvez ajuster cette valeur selon vos besoins

# Structurer les données pour toutes les catégories avec un délai entre les requêtes
structured_data = structure_data_for_all_categories(all_links, delay)

# Sauvegarder les données structurées dans un fichier JSON
save_to_json(structured_data, "all_categories_company_links.json")

puts "Structured data saved to all_categories_company_links.json"
