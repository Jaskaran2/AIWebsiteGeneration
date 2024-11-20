class WebsiteGeneratorService
  BASE_URL = "https://api.unsplash.com/search/photos"
  ACCESS_KEY = ENV['UNSPLASH_KEY']

  # Generate the website and fetch images for each section
  def self.generate_website(prompt)
    llm = Langchain::LLM::GoogleGemini.new(
      api_key: ENV['GEMINI_API_KEY']
    )

    response = llm.chat(
      messages: [
        { role: "user", parts: [{ text: website_prompt(prompt) }] }
      ]
    )

    raw_content = response.raw_response.dig("candidates", 0, "content", "parts", 0, "text")
    cleaned_content = raw_content.gsub(/```json\n/, "").gsub(/\n```/, "")
    generated_content = JSON.parse(cleaned_content)

    # Fetch images for each section
    add_images_to_sections(generated_content)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse Langchain response: #{e.message}")
    nil
  end

  private

  # Template for the prompt sent to the LLM
  def self.website_prompt(user_input)
    <<~PROMPT
      Generate a structured multi-page website for the following description:
      ---
      #{user_input}
      ---
      Include sections with titles, bodies, and image prompts. Return the output in JSON format:
      {
        "pages": [
          {
            "name": "Home",
            "content": {
              "heading": "string",
              "description": "string",
              "sections": [
                { "title": "string", "body": "string", "image_prompt": "string" }
              ]
            }
          }
        ]
      }
    PROMPT
  end

  def self.add_images_to_sections(content)
    content["pages"].each do |page|
      page["content"]["sections"].each do |section|
        image = fetch_image(section["image_prompt"])
        section["image_url"] = image[:url] if image
      end
    end
    content
  end

  # Fetch an image from Unsplash using the image prompt
  def self.fetch_image(query)
    response = HTTP.get(BASE_URL, params: { query: query, client_id: ACCESS_KEY, per_page: 1 })
    return nil unless response.status.success?

    result = JSON.parse(response.body.to_s)["results"].first

    {
      url: result["urls"]["regular"],
      alt: result["alt_description"] || "Image for #{query}"
    }
  end
end
