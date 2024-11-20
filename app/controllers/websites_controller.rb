class WebsitesController < ApplicationController
  def new
    @website = Website.new
  end

  def create
    @website = Website.new(name: params[:website][:name], description: params[:website][:description])

    generated_content = WebsiteGeneratorService.generate_website(@website.description)
    if generated_content.nil?
      flash[:alert] = "Failed to generate website. Try again."
      render :new and return
    end

    generated_pages = generated_content["pages"].map do |page_data|
      Page.new(name: page_data["name"], content: page_data["content"])
    end

    @website.pages = generated_pages

    if @website.save
      redirect_to website_path(@website)
    else
      flash[:alert] = "Failed to save website."
      render :new
    end
  end

  def show
    @website = Website.find(params[:id])
  end

  def page
    @website = Website.find(params[:id])
    page_data = @website.pages.find { |page| page["name"].downcase == params[:page_name].downcase }
    render html: render_page(page_data).html_safe
  end

  private

  def render_page(page_data)
    template = File.read(Rails.root.join("app/views/templates/#{page_data['name'].downcase}.liquid"))
    Liquid::Template.parse(template).render("content" => page_data["content"])
  end
end