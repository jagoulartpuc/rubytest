require 'dotenv/load'
require 'httparty'
require 'erb'

MARVEL_API_BASE_URL = 'https://gateway.marvel.com/v1/public'
PUBLIC_KEY = ENV['MARVEL_PUBLIC_KEY']
PRIVATE_KEY = ENV['MARVEL_PRIVATE_KEY']

def generate_auth_params
  ts = Time.now.to_i.to_s
  hash = Digest::MD5.hexdigest(ts + PRIVATE_KEY + PUBLIC_KEY)
  { ts: ts, apikey: PUBLIC_KEY, hash: hash }
end

def fetch_character_info(character_id)
    auth_params = generate_auth_params
    response = HTTParty.get("#{MARVEL_API_BASE_URL}/characters/#{character_id}", query: auth_params)
    if response.code == 200
      data = response.parsed_response['data']
      results = data['results']   
      if results.any?
        stories = results.first['stories']
        items = stories['items']
        stories_urls = items.map { |items| items['resourceURI'] }
        thumbnail = results.first['thumbnail']
        image_url = "#{thumbnail['path']}.#{thumbnail['extension']}"
        return stories_urls, image_url
      else
        puts 'No results found for this character.'
      end
    else
      puts "Error: API request failed with code #{response.code}"
    end
    nil
  end
  
def fetch_random_story_with_character(character_id)
  auth_params = generate_auth_params
  stories_url, image_url = fetch_character_info(character_id)
  response = HTTParty.get(stories_url.sample, query: auth_params)
  if response.code == 200
    data = response.parsed_response['data']
    results = data['results']
    if results.any?
      story = results.first   
      return story
    else
      puts 'No results found.'
    end
  else
    puts "Error: API request failed with code #{response.code}"
  end

  nil
end

def generate_marvel_story_html(character_name)
  story = fetch_random_story_with_character(character_name)
  return unless story

  description = story['description']
  characters = story['characters']['items']
  for character in characters
    character_id = character['resourceURI'].split('/').last
    _, image_url = fetch_character_info(character_id)
    character['resourceURI'] = image_url
  end
  html_template = ERB.new(File.read('template.html.erb'))
  File.write('marvel_story.html', html_template.result(binding))
end

generate_marvel_story_html('1009726') # X-Men