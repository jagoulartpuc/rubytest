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

def fetch_stories_by_character_id(character_id)
    auth_params = generate_auth_params
    response = HTTParty.get("#{MARVEL_API_BASE_URL}/characters/#{character_id}", query: auth_params)
    if response.code == 200
      data = response.parsed_response['data']
      results = data['results']
      character_name = results[0]['name']
      stories = results[0]['stories']
      if stories.any?
        items = stories['items']
        stories_urls = items.map { |items| items['resourceURI'] }
        return character_name, stories_urls
      else
        puts 'No stories found for this character.'
      end
    else
      puts "Error: API request failed with code #{response.code}"
    end
    nil
  end
  
def fetch_random_story_with_character(character_id)
  auth_params = generate_auth_params
  character_name, stories_url = fetch_stories_by_character_id(character_id)
  response = HTTParty.get(stories_url.sample, query: auth_params)
  if response.code == 200
    data = response.parsed_response['data']
    results = data['results']
    if results.any?
      story = results.first
      characters = story['characters']['items']
      character_names = characters.map { |char| char['name'] }
      if character_names.include?(character_name)
        return story
      end
    end
  end

  nil
end

def generate_marvel_story_html(character_name)
  story = fetch_random_story_with_character(character_name)
  return unless story

  description = story['description']
  characters = story['characters']['items']

  html_template = ERB.new(File.read('template.html.erb'))
  File.write('marvel_story.html', html_template.result(binding))
end

generate_marvel_story_html('1009726') # X-Men